part of 'pods.dart';

/// Provider for the main runner state and process lifecycle controller.
final runnerPod = NotifierProvider<RunnerPod, RunnerState>(RunnerPod.new);

/// Manages `~/.kickstarter` directories, background processes, 10s auto-restart, and 1s uptime ticks.
final class RunnerPod extends Notifier<RunnerState> {
  final Map<String, Process> _processes = {};
  final Map<String, Timer> _restartTimers = {};
  Timer? _tickTimer;

  late final PathsRepo _pathsRepo;
  late final ProcessService _processService;
  late final LaunchAgentService _agentService;

  @override
  RunnerState build() {
    final baseDir = PathsRepo.resolveBaseDir();
    _pathsRepo = PathsRepo(baseDir: baseDir);
    _processService = const ProcessService();
    _agentService = LaunchAgentService(baseDir: baseDir);

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(now: .now());
    });

    ref.onDispose(() {
      _tickTimer?.cancel();
      for (final timer in _restartTimers.values) {
        timer.cancel();
      }
      for (final proc in _processes.values) {
        unawaited(_processService.killProcessTree(proc));
      }
    });

    Future.microtask(reloadPaths);

    return RunnerState(
      baseDir: baseDir,
      now: .now(),
      launchAgentInstalled: _agentService.isInstalled,
    );
  }

  /// Ensures `~/.kickstarter/{worker,git-actions}/paths.json` exist and reconciles running services.
  Future<void> reloadPaths() async {
    final configured = await _pathsRepo.readAll();
    final configuredByPath = {for (final item in configured) item.path: item};
    final current = Map<String, ServiceItem>.of(state.services);

    final removed = current.keys
        .where((path) => !configuredByPath.containsKey(path))
        .toList();
    for (final path in removed) {
      await _stopInternal(path);
      current.remove(path);
    }

    final added = <String>[];
    for (final item in configured) {
      if (current[item.path] case final existing?) {
        current[item.path] = existing.copyWith(
          group: item.group,
          args: item.args,
        );
      } else {
        current[item.path] = item;
        added.add(item.path);
      }
    }

    final clearSelected =
        state.selectedLogPath != null &&
        !current.containsKey(state.selectedLogPath);
    state = state.copyWith(
      services: current,
      clearSelectedLog: clearSelected,
    );

    for (final path in added) {
      unawaited(startService(path));
    }
  }

  /// Opens native macOS file picker, appends selected files to [group]'s `paths.json`, and starts them.
  Future<void> pickAndAddFiles(ServiceGroup group) async {
    await _pathsRepo.ensureStructure();
    final picked = await _processService.pickFiles(
      defaultDir: _pathsRepo.groupDir(group),
    );
    if (picked.isEmpty) return;

    final current = Map<String, ServiceItem>.of(state.services);
    final added = <String>[];
    for (final path in picked) {
      if (current.containsKey(path)) continue;
      current[path] = ServiceItem(path: path, group: group);
      added.add(path);
    }
    if (added.isEmpty) return;

    state = state.copyWith(services: current);
    await _pathsRepo.writeGroup(group, current.values);

    for (final path in added) {
      unawaited(startService(path));
    }
  }

  /// Opens `~/.kickstarter/<group>` folder in Finder.
  Future<void> openGroupFolder(ServiceGroup group) async {
    await _pathsRepo.ensureStructure();
    await _processService.openFolder(_pathsRepo.groupDir(group));
  }

  /// Opens `~/.kickstarter/<group>/paths.json` in the system text editor.
  Future<void> openGroupPathsJson(ServiceGroup group) async {
    await _pathsRepo.ensureStructure();
    await _processService.openFile(_pathsRepo.groupJsonPath(group));
  }

  /// Starts or restarts the service at [path].
  Future<void> startService(String path) async {
    if (!state.services.containsKey(path)) return;

    _restartTimers.remove(path)?.cancel();
    if (_processes.remove(path) case final existingProc?) {
      await _processService.killProcessTree(existingProc);
    }

    if (!File(path).existsSync()) {
      _updateItem(path, (item) {
        return _appendLog(
          item.copyWith(status: .missing, clearStartedAt: true),
          'File not found: $path',
        );
      });
      return;
    }

    final currentArgs = state.services[path]?.args ?? const <String>[];
    final argsSuffix = currentArgs.isEmpty ? '' : ' ${currentArgs.join(' ')}';

    _updateItem(path, (item) {
      return _appendLog(
        item.copyWith(status: .running, startedAt: .now()),
        'Starting: $path$argsSuffix',
      );
    });

    try {
      final proc = await _processService.startScript(
        path: path,
        args: currentArgs,
        onLog: (line) {
          _updateItem(path, (item) => _appendLog(item, line));
        },
      );
      if (proc == null) return;
      _processes[path] = proc;

      final code = await proc.exitCode;
      if (_processes[path] != proc) return;
      _processes.remove(path);

      if (!state.services.containsKey(path)) return;
      final currentItem = state.services[path]!;
      if (currentItem.status == .stopped) return;

      _updateItem(path, (item) {
        return _appendLog(
          item.copyWith(
            status: .restarting,
            clearStartedAt: true,
            lastExitCode: code,
          ),
          'Exited with code $code. Restarting in 10s...',
        );
      });

      _restartTimers[path] = Timer(const Duration(seconds: 10), () {
        if (state.services[path]?.status == .restarting) {
          _updateItem(
            path,
            (item) => item.copyWith(restartCount: item.restartCount + 1),
          );
          unawaited(startService(path));
        }
      });
    } on Object catch (e) {
      _processes.remove(path);
      _updateItem(path, (item) {
        return _appendLog(
          item.copyWith(status: .stopped, clearStartedAt: true),
          'Start failed: $e',
        );
      });
    }
  }

  /// Manually stops a running or waiting service.
  Future<void> stopService(String path) async {
    await _stopInternal(path);
    _updateItem(path, (item) {
      return _appendLog(
        item.copyWith(status: .stopped, clearStartedAt: true),
        'Stopped by user.',
      );
    });
  }

  /// Stops a service and removes its entry from `<group>/paths.json`.
  Future<void> removeService(String path) async {
    final removedItem = state.services[path];
    await _stopInternal(path);
    final next = Map<String, ServiceItem>.of(state.services)..remove(path);
    state = state.copyWith(
      services: next,
      clearSelectedLog: state.selectedLogPath == path,
    );
    if (removedItem != null) {
      await _pathsRepo.writeGroup(removedItem.group, next.values);
    }
  }

  /// Updates the CLI arguments for [path], writes them to `<group>/paths.json`, and restarts if active.
  Future<void> updateArgs(String path, List<String> args) async {
    final existing = state.services[path];
    if (existing == null) return;

    final cleaned = args
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList(growable: false);
    final next = Map<String, ServiceItem>.of(state.services);
    next[path] = existing.copyWith(args: cleaned);
    state = state.copyWith(services: next);

    await _pathsRepo.writeGroup(existing.group, next.values);

    if (existing.status == .running || existing.status == .restarting) {
      unawaited(startService(path));
    }
  }

  /// Selects [path] to display in the log viewer panel (or closes it if `null`).
  void selectLog(String? path) {
    if (path == null) {
      state = state.copyWith(clearSelectedLog: true);
    } else {
      state = state.copyWith(selectedLogPath: path);
    }
  }

  /// Clears stored log lines for [path].
  void clearLogs(String path) {
    _updateItem(path, (item) => item.copyWith(logs: const []));
  }

  /// Installs or uninstalls the login LaunchAgent.
  Future<String> toggleLaunchAgent() async {
    state = state.copyWith(busyAgent: true);
    try {
      final msg = state.launchAgentInstalled
          ? await _agentService.uninstall()
          : await _agentService.install();
      state = state.copyWith(
        launchAgentInstalled: _agentService.isInstalled,
        busyAgent: false,
      );
      return msg;
    } on Object catch (e) {
      state = state.copyWith(busyAgent: false);
      return 'LaunchAgent error: $e';
    }
  }

  Future<void> _stopInternal(String path) async {
    _restartTimers.remove(path)?.cancel();
    if (_processes.remove(path) case final proc?) {
      await _processService.killProcessTree(proc);
    }
  }

  void _updateItem(String path, ServiceItem Function(ServiceItem) updater) {
    final existing = state.services[path];
    if (existing == null) return;
    final next = Map<String, ServiceItem>.of(state.services);
    next[path] = updater(existing);
    state = state.copyWith(services: next);
  }

  ServiceItem _appendLog(ServiceItem item, String line) {
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final nextLogs = [...item.logs, '[$stamp] $line'];
    if (nextLogs.length > 2000) {
      nextLogs.removeRange(0, nextLogs.length - 2000);
    }
    return item.copyWith(logs: nextLogs);
  }
}
