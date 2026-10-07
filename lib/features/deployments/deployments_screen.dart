import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/async_view.dart';
import 'deployments_provider.dart';
import 'widgets.dart';

class DeploymentsScreen extends ConsumerWidget {
  const DeploymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployments = ref.watch(runningDeploymentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deployments'),
        actions: [
          IconButton(
            onPressed: () async {
              ref.invalidate(runningDeploymentsProvider);
              await ref.read(runningDeploymentsProvider.future);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AsyncView(
        value: deployments,
        onRefresh: () async {
          ref.invalidate(runningDeploymentsProvider);
          await ref.read(runningDeploymentsProvider.future);
        },
        builder: (context, list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch_outlined,
                        size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('No deployments right now'),
                    SizedBox(height: 4),
                    Text('Trigger one from a resource page.',
                        style: TextStyle(color: Colors.white54)),
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