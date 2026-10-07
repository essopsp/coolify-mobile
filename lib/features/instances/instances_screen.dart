import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/coolify_instance.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../shared/widgets/confirm.dart';
import '../../shared/widgets/sections.dart';

class InstancesScreen extends ConsumerWidget {
  const InstancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(instancesProvider);
    final instances = async.value?.instances ?? const <CoolifyInstance>[];
    final activeId = async.value?.activeId;

    return Scaffold(
      appBar: AppBar(title: const Text('Coolify connections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/instances/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add instance'),
      ),
      body: async.hasError
          ? Center(child: Text('Failed to load: ${async.error}'))
          : instances.isEmpty
              ? const EmptyState(
                  icon: Icons.link_off,
                  title: 'No connections yet',
                  subtitle:
                      'Add your Coolify Cloud or self-hosted instance to get started.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: instances.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final instance = instances[i];
                    final active = instance.id == activeId;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: active
                              ? AppTheme.seed.withValues(alpha: 0.3)
                              : Colors.white10,
                          child: Icon(
                            active ? Icons.check : Icons.cloud_outlined,
                            color: active ? AppTheme.seed : Colors.white70,
                          ),
                        ),
                        title: Text(instance.name),
                        subtitle: Text(
                          '${instance.host}\n'
                          '${active ? '● Active' : 'Not active'}',
                          style: TextStyle(
                            color: active ? AppTheme.seed : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          if (active) return;
                          ref.read(instancesProvider.notifier).setActive(instance.id);
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            switch (v) {
                              case 'edit':
                                context.push('/instances/${instance.id}');
                              case 'remove':
                                final ok = await confirmAction(
                                  context,
                                  title: 'Remove connection?',
                                  message:
                                      '${instance.name} (${instance.host}) will be '
                                      'removed from this device only.',
                                  confirmLabel: 'Remove',
                                  destructive: true,
                                );
                                if (ok) {
                                  await ref
                                      .read(instancesProvider.notifier)
                                      .removeInstance(instance.id);
                                }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}