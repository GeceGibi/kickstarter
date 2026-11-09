part of 'repos.dart';

/// Repository managing `~/.kickstarter/<group>/paths.json` directories and files.
final class PathsRepo {
  const PathsRepo({required this.baseDir});

  final String baseDir;

  /// Resolves `~/.kickstarter` as the application home directory.
  static String resolveBaseDir() {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.kickstarter';
  }

  /// Path to a group directory (`~/.kickstarter/worker` or `~/.kickstarter/git-actions`).
  String groupDir(ServiceGroup group) => '$baseDir/${group.folderName}';

  /// Path to a group's `paths.json` file.
  String groupJsonPath(ServiceGroup group) =>
      '${groupDir(group)}/paths.json';

  /// Creates `~/.kickstarter/worker/paths.json` and `~/.kickstarter/git-actions/paths.json` if missing.
  Future<void> ensureStructure() async {
    for (final group in ServiceGroup.values) {
      final dir = Directory(groupDir(group));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final file = File(groupJsonPath(group));
      if (!file.existsSync()) {
        await file.writeAsString('[]\n');
      }
    }
  }

  /// Reads all configured [ServiceItem] entries across all groups.
  Future<List<ServiceItem>> readAll() async {
    await ensureStructure();
    final items = <ServiceItem>[];
    final seenPaths = <String>{};

    for (final group in ServiceGroup.values) {
      final file = File(groupJsonPath(group));
      if (!file.existsSync()) continue;
      final raw = (await file.readAsString()).trim();
      if (raw.isEmpty) continue;

      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        continue;
      }

      if (decoded case final List<Object?> list) {
        for (final entry in list) {
          final item = switch (entry) {
            final Map<String, Object?> map => ServiceItem.fromJson(map, group),
            final String pathStr => ServiceItem(
              path: pathStr.trim(),
              group: group,
            ),
            _ => null,
          };
          if (item != null &&
              item.path.isNotEmpty &&
              seenPaths.add(item.path)) {
            items.add(item);
          }
        }
      }
    }
    return items;
  }

  /// Writes all items belonging to [group] into `<group>/paths.json`.
  Future<void> writeGroup(
    ServiceGroup group,
    Iterable<ServiceItem> allItems,
  ) async {
    await ensureStructure();
    final payload = allItems
        .where((item) => item.group == group)
        .map((item) => item.toJson())
        .toList(growable: false);
    const encoder = JsonEncoder.withIndent('  ');
    await File(groupJsonPath(group)).writeAsString('${encoder.convert(payload)}\n');
  }
}
