import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tag.dart';
import '../../core/providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/confirm.dart';
import '../detail_providers.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key, required this.resource, required this.uuid});

  final String resource;
  final String uuid;

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  AsyncValue<List<ScheduledTask>> get _tasks =>
      widget.resource == 'application'
          ? ref.watch(appTasksProvider(widget.uuid))
          : ref.watch(serviceTasksProvider(widget.uuid));

  Future<void> _refresh() async {
    if (widget.resource == 'application') {
      ref.invalidate(appTasksProvider(widget.uuid));
      await ref.read(appTasksProvider(widget.uuid).future);
    } else {
      ref.invalidate(serviceTasksProvider(widget.uuid));
      await ref.read(serviceTasksProvider(widget.uuid).future);
    }
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<_TaskFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TaskForm(),
    );
    if (result == null || !mounted) return;
    await showBusy(
      context,
      action: () => ref.read(apiProvider).createTask(
            widget.resource,
            widget.uuid,
            name: result.name,
            command: result.command,
            frequency: result.frequency,
          ),
      successMessage: 'Scheduled task created.',
      busyLabel: 'Creating…',
    );
    await _refresh();
  }

  Future<void> _execute(ScheduledTask task) async {
    final uuid = task.uuid;
    if (uuid == null) return;
    await showBusy(
      context,
      action: () => ref
          .read(apiProvider)
          .executeTask(widget.resource, widget.uuid, uuid),
      successMessage: 'Execution queued.',
      busyLabel: 'Queuing…',
    );
  }

  Future<void> _delete(ScheduledTask task) async {
    final uuid = task.uuid;
    if (uuid == null) return;
    final ok = await confirmAction(
      context,
      title: 'Delete task?',
      message: task.name ?? 'This scheduled task',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    if (!mounted) return;
    await showBusy(
      context,
      action: () => ref
          .read(apiProvider)
          .deleteTask(widget.resource, widget.uuid, uuid),
      successMessage: 'Task deleted.',
      busyLabel: 'Deleting…',
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.schedule),
        label: const Text('New task'),
      ),
      body: AsyncView(
        value: _tasks,
        onRefresh: _refresh,
        builder: (context, list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No scheduled tasks.',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 90),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.amberAccent),
                    title: Text(t.name ?? '(unnamed)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⏱ ${t.frequency ?? '—'}'),
                        if (t.command != null && t.command!.isNotEmpty)
                          Text(
                            t.command!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 11),
                          ),
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
                          onPressed: () => _execute(t),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => _delete(t),
                        ),
                      ],
                    ),
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

class _TaskFormResult {
  const _TaskFormResult({
    required this.name,
    required this.command,
    required this.frequency,
  });

  final String name;
  final String command;
  final String frequency;
}

class _TaskForm extends StatefulWidget {
  const _TaskForm();

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TextEditingController _name;
  late final TextEditingController _command;
  late final TextEditingController _frequency;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _command = TextEditingController();
    _frequency = TextEditingController(text: '0 0 * * *');
  }

  @override
  void dispose() {
    _name.dispose();
    _command.dispose();
    _frequency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New scheduled task',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _command,
              maxLines: 3,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Command', hintText: 'e.g. php artisan schedule:run'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _frequency,
              decoration: const InputDecoration(
                  labelText: 'Cron expression',
                  hintText: '0 0 * * *'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _TaskFormResult(
                    name: _name.text.trim(),
                    command: _command.text.trim(),
                    frequency: _frequency.text.trim(),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}