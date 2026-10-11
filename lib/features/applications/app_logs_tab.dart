import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/log_viewer.dart';
import '../detail_providers.dart';

/// Logs tab for an application / database / service container.
///
/// Owns the "last N lines" and "timestamps" selection. [logsFor] resolves the
/// current query against a `WidgetRef`, so changing the query automatically
/// refetches because the caller passes a new [LogQuery] value.
class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({
    super.key,
    required this.logsFor,
    required this.onRefresh,
    this.notice = 'Logs require the read:sensitive token ability.',
  });

  /// Resolves the provider for a query, e.g.
  /// `(ref, q) => ref.watch(appLogsProvider(q))`.
  final AsyncValue<String> Function(WidgetRef ref, LogQuery q) logsFor;

  /// Invalidates whatever [logsFor] watches.
  final VoidCallback onRefresh;

  final String? notice;

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  int _lines = 200;
  bool _timestamps = false;

  LogQuery _query() => LogQuery(lines: _lines, timestamps: _timestamps);

  @override
  Widget build(BuildContext context) {
    final value = widget.logsFor(ref, _query());
    return Column(
      children: [
        if (widget.notice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.notice!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white38),
              ),
            ),
          ),
        Expanded(
          child: AsyncView<String>(
            value: value,
            onRefresh: () async => widget.onRefresh(),
            builder: (context, text) => LogViewer(
              logs: text,
              initialLineCount: _lines,
              initialTimestamps: _timestamps,
              onRefresh: widget.onRefresh,
              onLineCountChanged: (n) {
                widget.onRefresh();
                setState(() => _lines = n);
              },
              onTimestampsChanged: (t) {
                widget.onRefresh();
                setState(() => _timestamps = t);
              },
            ),
          ),
        ),
      ],
    );
  }
}