part of 'repos.dart';

/// Repository for resolving the project directory and persisting `kickstarter/paths`.
final class PathsRepo {
  const PathsRepo({required this.baseDir});

  final String baseDir;

  String get filePath => '$baseDir/paths';

  /// Resolves the `kickstarter` root directory from environment or executable path.
  static String resolveBaseDir() {
    if (Platform.environment['KICKSTARTER_DIR'] case final envDir?
        when envDir.isNotEmpty) {
      return envDir;
    }
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 8; i++) {
      if (File('${dir.path}/pubspec.yaml').existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return Directory.current.path;
  }

  /// Reads distinct non-empty paths from `kickstarter/paths`.
  Future<List<String>> readPaths() async {
    final file = File(filePath);
    if (!file.existsSync()) return const [];
    final configured = <String>[];
    for (final raw in await file.readAsLines()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (!configured.contains(line)) {
        configured.add(line);
      }
    }
    return configured;
  }

  /// Writes the given list of absolute paths to `kickstarter/paths`.
  Future<void> writePaths(Iterable<String> paths) async {
    final content = paths.join('\n');
    await File(filePath).writeAsString(content.isEmpty ? '' : '$content\n');
  }
}
