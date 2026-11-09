part of 'services.dart';

/// Service for native file picking, opening folders/files, and running background scripts.
final class ProcessService {
  const ProcessService();

  /// Opens the native macOS file picker (defaulting to [defaultDir]) and returns selected paths.
  Future<List<String>> pickFiles({String? defaultDir}) async {
    final defaultLocClause = switch (defaultDir) {
      final dir? when Directory(dir).existsSync() =>
        ' default location (POSIX file "$dir")',
      _ => '',
    };
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'set chosen to choose file with prompt "Select scripts or executables:"$defaultLocClause with multiple selections allowed',
      '-e',
      'set output to ""',
      '-e',
      'repeat with f in chosen',
      '-e',
      'set output to output & (POSIX path of f) & linefeed',
      '-e',
      'end repeat',
      '-e',
      'return output',
    ]);
    if (result.exitCode != 0) return const [];
    final out = (result.stdout as String).trim();
    if (out.isEmpty) return const [];
    return out
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Opens [folderPath] in macOS Finder.
  Future<void> openFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    await Process.run('/usr/bin/open', [folderPath]);
  }

  /// Opens [filePath] in the default macOS text editor.
  Future<void> openFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
      await file.writeAsString('[]\n');
    }
    await Process.run('/usr/bin/open', ['-t', filePath]);
  }

  /// Starts [path] with optional [args] under `/bin/zsh` after sourcing `~/.zprofile`.
  Future<Process?> startScript({
    required String path,
    List<String> args = const [],
    required void Function(String line) onLog,
  }) async {
    const script = r'''
if [[ -f "$HOME/.zprofile" ]]; then
  . "$HOME/.zprofile"
fi
target="$1"
shift
if [[ -x "$target" ]]; then
  "$target" "$@"
else
  /bin/zsh "$target" "$@"
fi
''';

    final proc = await Process.start(
      '/bin/zsh',
      ['-c', script, 'kickstarter-run', path, ...args],
      workingDirectory: File(path).parent.path,
      environment: {
        ...Platform.environment,
        'PATH':
            '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${Platform.environment['PATH'] ?? ''}',
        'PYTHONUNBUFFERED': '1',
      },
    );

    proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onLog);

    proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => onLog('[ERR] $line'));

    return proc;
  }

  /// Terminates [proc] and all of its descendant processes.
  Future<void> killProcessTree(Process proc) async {
    await _killChildren(proc.pid);
    proc.kill(.sigterm);
  }

  Future<void> _killChildren(int pid) async {
    final res = await Process.run('/usr/bin/pgrep', ['-P', '$pid']);
    if (res.exitCode != 0) return;
    for (final line in (res.stdout as String).split('\n')) {
      if (int.tryParse(line.trim()) case final childPid?) {
        await _killChildren(childPid);
        Process.killPid(childPid, .sigterm);
      }
    }
  }
}
