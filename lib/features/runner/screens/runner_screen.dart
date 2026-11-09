part of 'screens.dart';

/// Main dashboard screen displaying configured services and the optional log panel.
final class RunnerScreen extends ConsumerWidget {
  const RunnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runnerPod);
    final notifier = ref.read(runnerPod.notifier);
    final services = state.serviceList;
    final selected = state.selectedService;

    return Scaffold(
      body: Column(
        crossAxisAlignment: .stretch,
        children: [
          const HeaderBar(),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Expanded(
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: services.isEmpty
                      ? EmptyPathsView(
                          onAddWorker: () => notifier.pickAndAddFiles(.worker),
                          onAddGitAction: () =>
                              notifier.pickAndAddFiles(.gitActions),
                        )
                      : ListView.separated(
                          padding: const .all(16),
                          itemCount: services.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = services[index];
                            return ServiceRowCard(
                              item: item,
                              now: state.now,
                              isSelected: state.selectedLogPath == item.path,
                              onSelect: () => notifier.selectLog(item.path),
                              onStart: () => notifier.startService(item.path),
                              onStop: () => notifier.stopService(item.path),
                              onUpdateArgs: (args) =>
                                  notifier.updateArgs(item.path, args),
                              onRemove: () => notifier.removeService(item.path),
                            );
                          },
                        ),
                ),
                if (selected != null) ...[
                  const VerticalDivider(width: 1, color: Color(0xFF1E293B)),
                  Expanded(
                    flex: 6,
                    child: LogViewerPanel(
                      item: selected,
                      onClear: () => notifier.clearLogs(selected.path),
                      onClose: () => notifier.selectLog(null),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
