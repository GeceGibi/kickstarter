part of 'models.dart';

/// Immutable state for the runner feature.
final class RunnerState {
  const RunnerState({
    required this.baseDir,
    required this.now,
    this.services = const {},
    this.selectedLogPath,
    this.launchAgentInstalled = false,
    this.busyAgent = false,
  });

  final String baseDir;
  final DateTime now;
  final Map<String, ServiceItem> services;
  final String? selectedLogPath;
  final bool launchAgentInstalled;
  final bool busyAgent;

  String get pathsFilePath => '$baseDir/paths';

  List<ServiceItem> get serviceList => services.values.toList(growable: false);

  ServiceItem? get selectedService => switch (selectedLogPath) {
    final path? => services[path],
    null => null,
  };

  RunnerState copyWith({
    String? baseDir,
    DateTime? now,
    Map<String, ServiceItem>? services,
    String? selectedLogPath,
    bool clearSelectedLog = false,
    bool? launchAgentInstalled,
    bool? busyAgent,
  }) {
    return RunnerState(
      baseDir: baseDir ?? this.baseDir,
      now: now ?? this.now,
      services: services ?? this.services,
      selectedLogPath: clearSelectedLog
          ? null
          : (selectedLogPath ?? this.selectedLogPath),
      launchAgentInstalled: launchAgentInstalled ?? this.launchAgentInstalled,
      busyAgent: busyAgent ?? this.busyAgent,
    );
  }
}
