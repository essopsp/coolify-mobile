import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tag.dart';
import '../../core/providers.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';

class AuditEventsScreen extends ConsumerStatefulWidget {
  const AuditEventsScreen({super.key});

  @override
  ConsumerState<AuditEventsScreen> createState() => _AuditEventsScreenState();
}

class _AuditEventsScreenState extends ConsumerState<AuditEventsScreen> {
  Future<void> _refresh() async {
    ref.invalidate(auditEventsProvider);
    await ref.read(auditEventsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(auditEventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ]),
      body: AsyncView<List<AuditEvent>>(
        value: events,
        onRefresh: _refresh,
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No audit events',
              subtitle: 'Operations performed in this team will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final e = list[i];
                final action = e.action ?? '—';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                      child: Icon(e.statusIcon,
                          size: 18,
                          color: e.statusColor(context)),
                    ),
                    title: Text(action,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (e.userName != null)
                          Text(e.userName!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w500)),
                        if (e.createdAt != null)
                          Text(formatDateTime(e.createdAt!),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white38)),
                        if (e.details != null && e.details!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              e.details!.entries
                                  .map((kv) => '${kv.key}: ${kv.value}')
                                  .take(3)
                                  .join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white24),
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

extension on AuditEvent {
  IconData get statusIcon => Icons.history;

  Color statusColor(BuildContext context) => Colors.purpleAccent;
}