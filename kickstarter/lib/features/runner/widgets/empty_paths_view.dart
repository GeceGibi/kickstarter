part of 'widgets.dart';

/// Empty state widget displayed when neither `worker` nor `git-actions` has configured services.
final class EmptyPathsView extends StatelessWidget {
  const EmptyPathsView({
    required this.onAddWorker,
    required this.onAddGitAction,
    super.key,
  });

  final VoidCallback onAddWorker;
  final VoidCallback onAddGitAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          const Icon(
            Icons.terminal_rounded,
            size: 48,
            color: Color(0xFF475569),
          ),
          const SizedBox(height: 12),
          const Text(
            'No services configured',
            style: TextStyle(
              fontSize: 16,
              fontWeight: .w600,
              color: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick scripts or executables to add them to ~/.kickstarter/{worker,git-actions}/paths.json.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: .min,
            children: [
              FilledButton.icon(
                onPressed: onAddWorker,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Add Worker'),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: onAddGitAction,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Add Git-Action'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
