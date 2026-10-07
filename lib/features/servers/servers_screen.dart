import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/server.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import '../resources/resources_provider.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          IconButton(
            onPressed: () async {
              ref.invalidate(serversProvider);
              await ref.read(serversProvider.future);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncView<List<Server>>(
        value: servers,
        onRefresh: () async {
          ref.invalidate(serversProvider);
          await ref.read(serversProvider.future);
        },
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.dns,
              title: 'No servers',
              subtitle:
                  'Connect servers from the Coolify dashboard, then pull to refresh.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serversProvider);
              await ref.read(serversProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final s = list[i];
                final reachable = s.isReachable ?? false;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: reachable
                          ? Colors.greenAccent.withValues(alpha: 0.2)
                          : Colors.redAccent.withValues(alpha: 0.2),
                      child: Icon(
                        reachable ? Icons.dns : Icons.dns_outlined,
                        color: reachable ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      s.name ?? s.hostLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        s.hostLabel,
                        reachable ? 'online' : 'offline',
                        if (s.dockerVersion != null)
                          'docker ${s.dockerVersion}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: reachable
                        ? const Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 18)
                        : const Icon(Icons.error,
                            color: Colors.redAccent, size: 18),
                    onTap: () => context.push('/servers/${s.uuid}'),
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