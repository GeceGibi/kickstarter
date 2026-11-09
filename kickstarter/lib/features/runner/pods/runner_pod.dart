part of 'pods.dart';

/// Provider for the main runner state and process lifecycle controller.
final runnerPod = NotifierProvider<RunnerPod, RunnerState>(RunnerPod.new);

/// Manages background processes, 10s auto-restart timers, and 1s uptime ticks.
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

  /// Reads `kickstarter/paths` and reconciles running services.
  Future<void> reloadPaths() async {
    final configured = await _pathsRepo.readPaths();
    final current = Map<String, ServiceItem>.of(state.services);

    final removed = current.keys
        .where((path) => !configured.contains(path))
        .toList();
    for (final path in removed) {
      await _stopInternal(path);
      current.remove(path);
    }

    final added = <String>[];
    for (final path in configured) {
      if (!current.containsKey(path)) {
        current[path] = ServiceItem(path: path);
        added.add(path);
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

  /// Opens native macOS file picker, appends new paths, and starts them.
  Future<void> pickAndAddFiles() async {
    final picked = await _processService.pickFiles();
    if (picked.isEmpty) return;

    final current = Map<String, ServiceItem>.of(state.services);
    final added = <String>[];
    for (final path in picked) {
      if (current.containsKey(path)) continue;
      current[path] = ServiceItem(path: path);
      added.add(path);
    }
    if (added.isEmpty) return;

    state = state.copyWith(services: current);
    await _pathsRepo.writePaths(current.keys);

    for (final path in added) {
      unawaited(startService(path));
    }
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

    _updateItem(path, (item) {
      return _appendLog(
        item.copyWith(status: .running, startedAt: .now()),
        'Starting: $path',
      );
    });

    try {
      final proc = await _processService.startScript(
        path: path,
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

  /// Stops a service and removes its path from `kickstarter/paths`.
  Future<void> removeService(String path) async {
    await _stopInternal(path);
    final next = Map<String, ServiceItem>.of(state.services)..remove(path);
    state = state.copyWith(
      services: next,
      clearSelectedLog: state.selectedLogPath == path,
    );
    await _pathsRepo.writePaths(next.keys);
  }

  /// Toggles the log drawer for [path].
  void toggleLog(String? path) {
    if (path == null || state.selectedLogPath == path) {
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
