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

/// Row card displaying a service's status badge, uptime, path, arguments, and action buttons.
final class ServiceRowCard extends StatelessWidget {
  const ServiceRowCard({
    required this.item,
    required this.now,
    required this.isSelected,
    required this.onSelect,
    required this.onStart,
    required this.onStop,
    required this.onUpdateArgs,
    required this.onRemove,
    super.key,
  });

  final ServiceItem item;
  final DateTime now;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final ValueChanged<List<String>> onUpdateArgs;
  final VoidCallback onRemove;

  Future<void> _showArgsDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _ServiceArgsDialog(item: item),
    );
    if (result != null) {
      onUpdateArgs(result);
    }
  }

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

    return Material(
      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF152033),
      shape: RoundedRectangleBorder(
        borderRadius: .circular(10),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : const Color(0xFF1E293B),
        ),
      ),
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onSelect,
        hoverColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
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
                            padding: const .symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                    if (item.args.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final arg in item.args)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: .circular(4),
                                border: .all(color: const Color(0xFF334155)),
                              ),
                              child: Padding(
                                padding: const .symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  arg,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF38BDF8),
                                    fontFamily: 'Menlo',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showArgsDialog(context),
                style: OutlinedButton.styleFrom(
                  visualDensity: .compact,
                  padding: const .symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(
                    color: item.args.isNotEmpty
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                        : const Color(0xFF334155),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 15,
                  color: Color(0xFF38BDF8),
                ),
                label: Text(
                  item.args.isEmpty ? 'Args' : 'Args (${item.args.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
      ),
    );
  }
}

final class _ServiceArgsDialog extends StatefulWidget {
  const _ServiceArgsDialog({required this.item});

  final ServiceItem item;

  @override
  State<_ServiceArgsDialog> createState() => _ServiceArgsDialogState();
}

final class _ServiceArgsDialogState extends State<_ServiceArgsDialog> {
  late final List<String> _args;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _args = List<String>.of(widget.item.args);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addCurrentInput() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final parts = _splitShellArgs(raw);
    if (parts.isEmpty) return;
    setState(() {
      _args.addAll(parts);
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  List<String> _splitShellArgs(String input) {
    final result = <String>[];
    final current = StringBuffer();
    String? quote;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (quote != null) {
        if (char == quote) {
          quote = null;
        } else {
          current.write(char);
        }
      } else if (char == '"' || char == "'") {
        quote = char;
      } else if (char == ' ' || char == '\t') {
        if (current.isNotEmpty) {
          result.add(current.toString());
          current.clear();
        }
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      result.add(current.toString());
    }
    return result;
  }

  void _save() {
    if (_controller.text.trim().isNotEmpty) {
      _addCurrentInput();
    }
    Navigator.of(context).pop(_args);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      title: Column(
        crossAxisAlignment: .start,
        children: [
          const Text(
            'Arguments / Parameters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: .w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.name,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Menlo',
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Menlo',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. --port 8080 --env prod',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: .circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: .circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    onSubmitted: (_) => _addCurrentInput(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _addCurrentInput,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_args.isEmpty)
              const Padding(
                padding: .symmetric(vertical: 12),
                child: Text(
                  'No arguments configured.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _args.length; i++)
                    InputChip(
                      label: Text(
                        _args[i],
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Menlo',
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      backgroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF334155)),
                      deleteIconColor: const Color(0xFF94A3B8),
                      onDeleted: () {
                        setState(() {
                          _args.removeAt(i);
                        });
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        if (_args.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(_args.clear);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
