import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/async_view.dart';
import 'deployments_provider.dart';
import 'widgets.dart';

class ApplicationDeploymentsScreen extends ConsumerWidget {
  const ApplicationDeploymentsScreen({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployments = ref.watch(appDeploymentsProvider(uuid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deployment history'),
        actions: [
          IconButton(
            onPressed: () async {
              ref.invalidate(appDeploymentsProvider(uuid));
              await ref.read(appDeploymentsProvider(uuid).future);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AsyncView(
        value: deployments,
        onRefresh: () async {
          ref.invalidate(appDeploymentsProvider(uuid));
          await ref.read(appDeploymentsProvider(uuid).future);
        },
        builder: (context, list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('No deployments yet'),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
            itemCount: list.length,
            itemBuilder: (context, i) =>
                DeploymentTile(deployment: list[i]),
          );
        },
      ),
    );
  }
}
