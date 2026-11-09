part of 'models.dart';

/// Lifecycle status of a managed service.
enum ServiceStatus { running, restarting, stopped, missing }

/// Category folder under `~/.kickstarter/<folderName>/paths.json`.
enum ServiceGroup {
  worker('worker'),
  gitActions('git-actions');

  const ServiceGroup(this.folderName);

  final String folderName;
}

/// Immutable representation of a single service entry in `paths.json`.
final class ServiceItem {
  const ServiceItem({
    required this.path,
    required this.group,
    this.status = .stopped,
    this.startedAt,
    this.lastExitCode,
    this.restartCount = 0,
    this.logs = const [],
  });

  factory ServiceItem.fromJson(
    Map<String, Object?> json,
    ServiceGroup group,
  ) {
    final rawPath = switch (json['path']) {
      final String s => s.trim(),
      _ => '',
    };
    return ServiceItem(path: rawPath, group: group);
  }

  final String path;
  final ServiceGroup group;
  final ServiceStatus status;
  final DateTime? startedAt;
  final int? lastExitCode;
  final int restartCount;
  final List<String> logs;

  /// Serializes this item for `paths.json`.
  Map<String, Object?> toJson() => {'path': path};

  /// Short display name (`parent/file`).
  String get name {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    return switch (parts) {
      [..., final parent, final file] => '$parent/$file',
      [final single] => single,
      _ => path,
    };
  }

  /// Elapsed duration since [startedAt] when [status] is [ServiceStatus.running].
  Duration? uptime(DateTime now) => switch ((status, startedAt)) {
    (.running, final start?) => now.difference(start),
    _ => null,
  };

  /// Returns a copy with updated fields.
  ServiceItem copyWith({
    ServiceGroup? group,
    ServiceStatus? status,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? lastExitCode,
    int? restartCount,
    List<String>? logs,
  }) {
    return ServiceItem(
      path: path,
      group: group ?? this.group,
      status: status ?? this.status,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      lastExitCode: lastExitCode ?? this.lastExitCode,
      restartCount: restartCount ?? this.restartCount,
      logs: logs ?? this.logs,
    );
  }
}
