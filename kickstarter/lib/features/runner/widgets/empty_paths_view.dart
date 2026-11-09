part of 'widgets.dart';

/// Empty state widget displayed when `kickstarter/paths` has no configured scripts.
final class EmptyPathsView extends StatelessWidget {
  const EmptyPathsView({required this.onAdd, super.key});

  final VoidCallback onAdd;

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
            'Pick scripts or executables to add them to kickstarter/paths.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Select File to Add'),
          ),
        ],
      ),
    );
  }
}
