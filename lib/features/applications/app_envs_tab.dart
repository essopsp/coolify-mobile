import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/environment.dart';
import '../../core/providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/confirm.dart';
import '../detail_providers.dart';

class EnvVarsTab extends ConsumerStatefulWidget {
  const EnvVarsTab({
    super.key,
    required this.resource,
    required this.uuid,
    required this.envProvider,
  });

  final String resource;
  final String uuid;
  final AsyncValue<List<EnvVar>> envProvider;

  @override
  ConsumerState<EnvVarsTab> createState() => _EnvVarsTabState();
}

class _EnvVarsTabState extends ConsumerState<EnvVarsTab> {
  bool _showValues = false;

  Future<void> _refresh() async {
    if (widget.resource == 'application') {
      ref.invalidate(appEnvVarsProvider(widget.uuid));
      await ref.read(appEnvVarsProvider(widget.uuid).future);
    } else {
      ref.invalidate(dbEnvVarsProvider(widget.uuid));
      await ref.read(dbEnvVarsProvider(widget.uuid).future);
    }
  }

  Future<void> _editEnv({EnvVar? existing}) async {
    final result = await showModalBottomSheet<_EnvFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EnvForm(
        existing: existing,
        allowValueEdit: _showValues || existing?.value == null,
      ),
    );
    if (result == null || !mounted) return;

    await showBusy(
      context,
      action: () async {
        final api = ref.read(apiProvider);
        if (existing != null) {
          await api.patchEnvVarsBulk(
            widget.resource,
            widget.uuid,
            key: result.key,
            value: result.value,
            buildTime: result.buildTime,
            preview: result.preview,
          );
        } else {
          await api.addEnvVars(
            widget.resource,
            widget.uuid,
            key: result.key,
            value: result.value,
            buildTime: result.buildTime,
            preview: result.preview,
          );
        }
      },
      successMessage: existing != null ? 'Variable updated.' : 'Variable added.',
      busyLabel: 'Saving…',
    );
    await _refresh();
  }

  Future<void> _deleteEnv(EnvVar env) async {
    final ok = await confirmAction(
      context,
      title: 'Delete variable?',
      message: '${env.key} will be removed from the resource.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final uuid = env.uuid;
    if (uuid == null) return;
    if (!mounted) return;
    await showBusy(
      context,
      action: () =>
          ref.read(apiProvider).deleteEnvVar(widget.resource, widget.uuid, uuid),
      successMessage: 'Variable deleted.',
      busyLabel: 'Deleting…',
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final envs = widget.envProvider;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editEnv(),
        icon: const Icon(Icons.add),
        label: const Text('Add var'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Spacer(),
                Text('Reveal values',
                    style: Theme.of(context).textTheme.labelSmall),
                Switch(
                  value: _showValues,
                  onChanged: (v) => setState(() => _showValues = v),
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView(
              value: envs,
              onRefresh: _refresh,
              builder: (context, list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No environment variables set.',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 90),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final env = list[i];
                      final value = _showValues ? (env.value ?? '(hidden)') : '(hidden)';
                      return Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(env.key ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (env.isBuildTime ?? false)
                                _Badge('build', Colors.amberAccent),
                              if (env.isPreview ?? false)
                                _Badge('preview', Colors.lightBlueAccent),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              value,
                              maxLines: env.isMultiline ?? false ? 6 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: env.isSecret
                                    ? Colors.deepOrangeAccent
                                    : Colors.white70,
                              ),
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => _editEnv(existing: env),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _deleteEnv(env),
                          ),
                        ),
                      );
                    },
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

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color)),
    );
  }
}

class _EnvFormResult {
  const _EnvFormResult({
    required this.key,
    required this.value,
    required this.buildTime,
    required this.preview,
  });

  final String key;
  final String? value;
  final bool buildTime;
  final bool preview;
}

class _EnvForm extends StatefulWidget {
  const _EnvForm({this.existing, required this.allowValueEdit});

  final EnvVar? existing;
  final bool allowValueEdit;

  @override
  State<_EnvForm> createState() => _EnvFormState();
}

class _EnvFormState extends State<_EnvForm> {
  late final TextEditingController _key;
  late final TextEditingController _value;
  bool _buildTime = false;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(text: widget.existing?.key ?? '');
    _value = TextEditingController(text: widget.existing?.value ?? '');
    _buildTime = widget.existing?.isBuildTime ?? false;
    _preview = widget.existing?.isPreview ?? false;
  }

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    final key = _key.text.trim();
    if (key.isEmpty) return;
    Navigator.pop(
      context,
      _EnvFormResult(
        key: key,
        value: _value.text.isEmpty ? null : _value.text,
        buildTime: _buildTime,
        preview: _preview,
      ),
    );
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
            Text(
              widget.existing == null ? 'Add variable' : 'Edit variable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _key,
              decoration: const InputDecoration(
                  labelText: 'Key', hintText: 'MY_VARIABLE'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              enabled: widget.allowValueEdit,
              maxLines: 4,
              minLines: 1,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
            SwitchListTile(
              value: _buildTime,
              onChanged: (v) => setState(() => _buildTime = v),
              title: const Text('Build time variable'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _preview,
              onChanged: (v) => setState(() => _preview = v),
              title: const Text('Preview variable'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}