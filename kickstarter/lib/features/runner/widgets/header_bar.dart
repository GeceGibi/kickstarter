part of 'widgets.dart';

/// Top application toolbar showing active service count, `paths` location, and controls.
final class HeaderBar extends ConsumerWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runnerPod);
    final notifier = ref.read(runnerPod.notifier);
    final runningCount = state.serviceList
        .where((item) => item.status == .running)
        .length;
    final totalCount = state.serviceList.length;

    return ColoredBox(
      color: const Color(0xFF111827),
      child: Padding(
        padding: const .symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFF38BDF8), size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Kickstarter',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: .w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: .circular(999),
                      ),
                      child: Padding(
                        padding: const .symmetric(horizontal: 10, vertical: 3),
                        child: Text(
                          '$runningCount / $totalCount running',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: .w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  state.pathsFilePath,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Menlo',
                  ),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: state.busyAgent
                  ? null
                  : () async {
                      final msg = await notifier.toggleLaunchAgent();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              icon: Icon(
                state.launchAgentInstalled
                    ? Icons.check_circle_rounded
                    : Icons.power_settings_new_rounded,
                size: 16,
                color: state.launchAgentInstalled
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF94A3B8),
              ),
              label: Text(
                state.launchAgentInstalled
                    ? 'Login Agent Active'
                    : 'Install Login Agent',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Reload paths file',
              onPressed: notifier.reloadPaths,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: notifier.pickAndAddFiles,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add File'),
            ),
          ],
        ),
      ),
    );
  }
}
