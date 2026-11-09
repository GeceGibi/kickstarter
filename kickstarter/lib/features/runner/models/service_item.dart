part of 'models.dart';

/// Lifecycle status of a managed service.
enum ServiceStatus { running, restarting, stopped, missing }

/// Immutable representation of a single service entry from `kickstarter/paths`.
final class ServiceItem {
  const ServiceItem({
    required this.path,
    this.status = .stopped,
    this.startedAt,
    this.lastExitCode,
    this.restartCount = 0,
    this.logs = const [],
  });

  final String path;
  final ServiceStatus status;
  final DateTime? startedAt;
  final int? lastExitCode;
  final int restartCount;
  final List<String> logs;

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
    ServiceStatus? status,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? lastExitCode,
    int? restartCount,
    List<String>? logs,
  }) {
    return ServiceItem(
      path: path,
      status: status ?? this.status,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      lastExitCode: lastExitCode ?? this.lastExitCode,
      restartCount: restartCount ?? this.restartCount,
      logs: logs ?? this.logs,
    );
  }
}
