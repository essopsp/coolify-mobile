import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/async_view.dart';

/// Generic logs tab fed by a provider that returns raw log text.
class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({
    super.key,
    required this.logProvider,
    required this.onRefresh,
  });

  final AsyncValue<String> logProvider;
  final VoidCallback onRefresh;

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  @override
  Widget build(BuildContext context) {
    final logs = widget.logProvider;
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Spacer(),
                Text('Logs require the read:sensitive token ability.',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white38)),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh logs',
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView(
              value: logs,
              onRefresh: () async => widget.onRefresh(),
              builder: (context, text) {
                return SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      text.isEmpty ? '(no output yet)' : text,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFFD8E1EC),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}