part of 'widgets.dart';

/// Formats an uptime [Duration] into a concise `02h 14m 08s` string.
String formatUptime(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

/// Row card displaying a service's status badge, uptime, path, and action buttons.
final class ServiceRowCard extends StatelessWidget {
  const ServiceRowCard({
    required this.item,
    required this.now,
    required this.isSelected,
    required this.onStart,
    required this.onStop,
    required this.onToggleLog,
    required this.onRemove,
    super.key,
  });

  final ServiceItem item;
  final DateTime now;
  final bool isSelected;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onToggleLog;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeText) = switch (item.status) {
      .running => (const Color(0xFF22C55E), 'Running'),
      .restarting => (const Color(0xFFF59E0B), 'Restarting (10s)'),
      .stopped => (const Color(0xFF64748B), 'Stopped'),
      .missing => (const Color(0xFFEF4444), 'Missing File'),
    };

    final isActive = item.status == .running || item.status == .restarting;
    final currentUptime = item.uptime(now);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF152033),
        borderRadius: .circular(10),
        border: .all(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : const Color(0xFF1E293B),
        ),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: badgeColor,
                shape: .circle,
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          overflow: .ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: .w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: .circular(6),
                        ),
                        child: Padding(
                          padding: const .symmetric(horizontal: 8, vertical: 2),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: .w600,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ),
                      if (currentUptime != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatUptime(currentUptime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Menlo',
                          ),
                        ),
                      ],
                      if (item.restartCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '↻ ${item.restartCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.path,
                    overflow: .ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontFamily: 'Menlo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isActive)
              IconButton(
                tooltip: 'Stop',
                onPressed: onStop,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: Color(0xFFF87171),
                ),
              )
            else
              IconButton(
                tooltip: 'Start',
                onPressed: onStart,
                icon: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Color(0xFF4ADE80),
                ),
              ),
            IconButton(
              tooltip: 'Restart',
              onPressed: onStart,
              icon: const Icon(
                Icons.restart_alt_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onToggleLog,
              icon: const Icon(Icons.article_outlined, size: 16),
              label: Text(isSelected ? 'Hide Logs' : 'Logs'),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Remove from paths',
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
