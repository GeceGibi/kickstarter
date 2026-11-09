part of 'widgets.dart';

/// Side panel displaying live stdout/stderr output for the selected service.
final class LogViewerPanel extends StatelessWidget {
  const LogViewerPanel({
    required this.item,
    required this.onClear,
    required this.onClose,
    super.key,
  });

  final ServiceItem item;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = item.logs.isEmpty ? 'No log output yet.' : item.logs.join('\n');

    return ColoredBox(
      color: const Color(0xFF0B1120),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ColoredBox(
            color: const Color(0xFF111827),
            child: Padding(
              padding: const .symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.terminal_rounded,
                    size: 16,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Logs: ${item.name}',
                      overflow: .ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: .w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy logs',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                  ),
                  IconButton(
                    tooltip: 'Clear logs',
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              padding: const .all(14),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 12,
                  height: 1.45,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
