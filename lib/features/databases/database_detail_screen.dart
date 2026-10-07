import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/database.dart';
import '../../core/models/resource.dart';
import '../../core/providers.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/confirm.dart';
import '../../shared/widgets/sections.dart';
import '../../shared/widgets/status_chip.dart';
import '../applications/app_envs_tab.dart';
import '../applications/app_logs_tab.dart';
import '../detail_providers.dart';
import '../resources/widgets.dart';

class DatabaseDetailScreen extends ConsumerStatefulWidget {
  const DatabaseDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<DatabaseDetailScreen> createState() =>
      _DatabaseDetailScreenState();
}

class _DatabaseDetailScreenState extends ConsumerState<DatabaseDetailScreen> {
  int _tab = 0;

  Future<void> _refresh() async {
    ref.invalidate(databaseProvider(widget.uuid));
    await ref.read(databaseProvider(widget.uuid).future);
  }

  Future<void> _action(String action) async {
    await performControl(
      context,
      ref,
      type: ResourceType.database,
      uuid: widget.uuid,
      action: action,
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider(widget.uuid));
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Database'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ]),
      body: AsyncView(
        value: db,
        onRefresh: _refresh,
        builder: (context, d) {
          final status = d.parsedStatus;
          final tabs = <Widget>[
            const Tab(text: 'Overview'),
            const Tab(text: 'Env'),
            const Tab(text: 'Logs'),
            const Tab(text: 'Backups'),
          ];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    StatusChip(status),
                    const Spacer(),
                    _IconAction(
                      icon: Icons.play_circle_outline,
                      color: Colors.greenAccent,
                      tooltip: 'Start',
                      onTap: () => _action('start'),
                    ),
                    _IconAction(
                      icon: Icons.restart_alt,
                      color: Colors.amberAccent,
                      tooltip: 'Restart',
                      onTap: () => _action('restart'),
                    ),
                    _IconAction(
                      icon: Icons.stop_circle_outlined,
                      color: scheme.error,
                      tooltip: 'Stop',
                      onTap: () => _action('stop'),
                    ),
                  ],
                ),
              ),
              DefaultTabController(
                length: tabs.length,
                child: Column(
                  children: [
                    TabBar(
                      onTap: (i) => setState(() => _tab = i),
                      tabs: tabs,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height - 320,
                      ),
                      child: switch (_tab) {
                        0 => _DbOverview(db: d),
                        1 => EnvVarsTab(
                            resource: 'database',
                            uuid: widget.uuid,
                            envProvider: ref.watch(dbEnvVarsProvider(widget.uuid)),
                          ),
                        2 => LogsTab(
                            logProvider: ref.watch(dbLogsProvider(widget.uuid)),
                            onRefresh: () {
                              ref.invalidate(dbLogsProvider(widget.uuid));
                            },
                          ),
                        _ => _BackupsTab(dbUuid: widget.uuid),
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, color: color), tooltip: tooltip, onPressed: onTap);
  }
}

class _DbOverview extends StatelessWidget {
  const _DbOverview({required this.db});

  final Database db;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Database',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('Name', db.name),
              InfoRow('Engine', db.dbEngine ?? db.image ?? '—'),
              if (db.fqdn != null && db.fqdn!.isNotEmpty)
                InfoRow('Domain', db.fqdn),
              InfoRow('Ports', db.portsMappings?.isNotEmpty == true
                  ? db.portsMappings
                  : db.portsExposes ?? '—'),
              InfoRow('Public', db.isPublic == null
                  ? '—'
                  : (db.isPublic! ? 'Yes' : 'No')),
              if (db.description != null && db.description!.isNotEmpty)
                InfoRow('Description', db.description),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Metadata',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('UUID', db.uuid),
              InfoRow('Created', formatDateTime(db.createdAt)),
              InfoRow('Updated', formatDateTime(db.updatedAt)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupsTab extends ConsumerStatefulWidget {
  const _BackupsTab({required this.dbUuid});

  final String dbUuid;

  @override
  ConsumerState<_BackupsTab> createState() => _BackupsTabState();
}

class _BackupsTabState extends ConsumerState<_BackupsTab> {
  Future<void> _refresh() async {
    ref.invalidate(dbBackupsProvider(widget.dbUuid));
    await ref.read(dbBackupsProvider(widget.dbUuid).future);
  }

  Future<void> _add() async {
    final freq =
        await showDialog<String>(
          context: context,
          builder: (ctx) {
            final freqController = TextEditingController(text: '0 0 * * *');
            return AlertDialog(
              title: const Text('New backup schedule'),
              content: TextField(
                controller: freqController,
                decoration: const InputDecoration(
                    labelText: 'Cron expression'),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, freqController.text.trim()),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
    if (freq == null || !mounted) return;
    await showBusy(
      context,
      action: () => ref.read(apiProvider).createBackup(widget.dbUuid, frequency: freq),
      successMessage: 'Backup schedule created.',
      busyLabel: 'Creating…',
    );
    await _refresh();
  }

  Future<void> _run(Backup b) async {
    final uuid = b.uuid;
    if (uuid == null) return;
    await showBusy(
      context,
      action: () => ref.read(apiProvider).runBackup(widget.dbUuid, uuid),
      successMessage: 'Backup started.',
      busyLabel: 'Starting backup…',
    );
    await _refresh();
  }

  Future<void> _delete(Backup b) async {
    final uuid = b.uuid;
    if (uuid == null) return;
    final ok = await confirmAction(
      context,
      title: 'Delete backup schedule?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    if (!mounted) return;
    await showBusy(
      context,
      action: () => ref.read(apiProvider).deleteBackup(widget.dbUuid, uuid),
      successMessage: 'Backup schedule removed.',
      busyLabel: 'Deleting…',
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final backups = ref.watch(dbBackupsProvider(widget.dbUuid));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ),
      body: AsyncView(
        value: backups,
        onRefresh: _refresh,
        builder: (context, list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No backup schedules.',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 90),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final b = list[i];
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup_outlined,
                            color: Colors.lightBlueAccent),
                        title: Text(b.name ?? b.frequency ?? 'Backup'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cron: ${b.frequency ?? '—'}'),
                            if (b.lastExecutionAt != null)
                              Text('Last: ${formatDateTime(b.lastExecutionAt)}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow,
                                  color: Colors.greenAccent),
                              tooltip: 'Run now',
                              onPressed: () => _run(b),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Delete',
                              onPressed: () => _delete(b),
                            ),
                          ],
                        ),
                      ),
                      _Executions(dbUuid: widget.dbUuid, backupUuid: b.uuid!),
                    ],
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

class _Executions extends ConsumerWidget {
  const _Executions({required this.dbUuid, required this.backupUuid});

  final String dbUuid;
  final String backupUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execs = ref.watch(
      dbBackupExecutionsProvider((db: dbUuid, backup: backupUuid)),
    );
    final list = execs.value;
    if (list == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in list.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    e.status == 'success'
                        ? Icons.check_circle_outline
                        : e.status == 'running'
                            ? Icons.sync
                            : Icons.error_outline,
                    size: 15,
                    color: e.status == 'success'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (e.message ?? e.status ?? '—'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ),
                  Text(
                    formatDateTime(e.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}