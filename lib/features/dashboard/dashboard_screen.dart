import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/resource.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../deployments/deployments_provider.dart';
import '../resources/resources_provider.dart';
import '../resources/widgets.dart';
import '../projects/projects_provider.dart';
import '../deployments/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instance = ref.watch(activeInstanceProvider);
    final team = ref.watch(currentTeamProvider).value;
    final version = ref.watch(apiVersionProvider).value;

    final resources = ref.watch(resourcesProvider).value;
    final apps = resources?.where((r) => r.type == ResourceType.application).length ?? 0;
    final dbs = resources?.where((r) => r.type == ResourceType.database).length ?? 0;
    final svcs = resources?.where((r) => r.type == ResourceType.service).length ?? 0;
    final servers = (ref.watch(serversProvider).value)?.length ?? 0;
    final projects = (ref.watch(projectsProvider).value)?.length ?? 0;

    final needingAttention = (resources ?? const <Resource>[])
        .where((r) => r.parsedStatus.isFailed ||
            (r.parsedStatus.isExited && !r.parsedStatus.isCanceled))
        .toList();

    final running = ref.watch(runningDeploymentsProvider).value;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resourcesProvider);
          ref.invalidate(runningDeploymentsProvider);
          ref.invalidate(apiVersionProvider);
          ref.invalidate(currentTeamProvider);
          await Future.wait([
            ref.read(resourcesProvider.future),
            ref.read(runningDeploymentsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.seed.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.rocket_launch,
                            color: AppTheme.seed, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instance?.name ?? 'Coolify',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              [
                                instance?.host,
                                if (version != null) 'v$version',
                                team?.name,
                              ].whereType<String>().join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cloud_queue),
                        tooltip: 'Connections',
                        onPressed: () => context.push('/instances'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(scheme, Icons.dns_outlined, servers,
                                'Servers', () => context.go('/servers')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(scheme, Icons.folder_outlined,
                                projects, 'Projects',
                                () => context.push('/projects')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(scheme, Icons.web_asset, apps,
                                'Apps', () => context.go('/resources')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(scheme, Icons.storage, dbs,
                                'Databases', () => context.go('/resources')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(scheme, Icons.layers, svcs,
                                'Services', () => context.go('/resources')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                                scheme,
                                Icons.rocket_launch_outlined,
                                running?.length ?? 0,
                                'Deploying',
                                () => context.go('/deployments')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.go('/deployments'),
                        icon: const Icon(Icons.history),
                        label: const Text('View deployments'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (needingAttention.isNotEmpty) ...[
              const _SectionTitle('Needs attention'),
              for (final r in needingAttention.take(6))
                ResourceCard(resource: r, onTap: () => openResource(context, r)),
            ],
            if (running != null && running.isNotEmpty) ...[
              const _SectionTitle('Running deployments'),
              for (final d in running.take(5)) DeploymentTile(deployment: d),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.scheme, this.icon, this.value, this.label, this.onTap);

  final ColorScheme scheme;
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}