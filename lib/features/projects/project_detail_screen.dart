import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/environment.dart';
import '../../core/models/resource.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import '../resources/widgets.dart';
import 'projects_provider.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int _tab = 0;

  Future<void> _refresh() async {
    ref.invalidate(projectProvider(widget.uuid));
    ref.invalidate(projectResourcesProvider(
      (project: widget.uuid, environment: null),
    ));
    await ref.read(projectProvider(widget.uuid).future);
    await ref
        .read(projectResourcesProvider(
          (project: widget.uuid, environment: null),
        )
        .future);
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.uuid));
    return Scaffold(
      appBar: AppBar(title: const Text('Project'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ]),
      body: AsyncView(
        value: project,
        onRefresh: _refresh,
        builder: (context, p) {
          final tabs = <Widget>[
            Tab(text: 'Environments (${p.environments.length})'),
            const Tab(text: 'Resources'),
          ];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name ?? '(unnamed)',
                              style: Theme.of(context).textTheme.titleLarge),
                          if (p.description != null)
                            Text(
                              p.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white54),
                            ),
                        ],
                      ),
                    ),
                    if (p.counts != null)
                      Column(
                        children: [
                          Text(
                            '${p.counts!.total}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Text('resources',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                  ],
                ),
              ),
              TabBar(
                onTap: (i) => setState(() => _tab = i),
                tabs: tabs,
              ),
              Expanded(
                child: switch (_tab) {
                  0 => _EnvsList(
                      envs: p.environments,
                      projectUuid: widget.uuid,
                    ),
                  _ => _ProjectResources(projectUuid: widget.uuid),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EnvsList extends StatelessWidget {
  const _EnvsList({required this.envs, required this.projectUuid});

  final List<Environment> envs;
  final String projectUuid;

  @override
  Widget build(BuildContext context) {
    if (envs.isEmpty) {
      return const EmptyState(
        icon: Icons.memory,
        title: 'No environments',
        subtitle: 'Add an environment from the Coolify dashboard.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: envs.length,
      itemBuilder: (context, i) {
        final e = envs[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.memory),
            title: Text(e.name ?? '(unnamed)',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(e.description ?? e.uuid ?? ''),
            onTap: () {
              context.push(
                '/projects/$projectUuid/env/${e.name ?? e.uuid}',
                extra: e,
              );
            },
          ),
        );
      },
    );
  }
}

class _ProjectResources extends ConsumerStatefulWidget {
  const _ProjectResources({required this.projectUuid});

  final String projectUuid;

  @override
  ConsumerState<_ProjectResources> createState() => _ProjectResourcesState();
}

class _ProjectResourcesState extends ConsumerState<_ProjectResources> {
  Future<void> _refresh() async {
    ref.invalidate(projectResourcesProvider(
      (project: widget.projectUuid, environment: null),
    ));
    await ref
        .read(projectResourcesProvider(
          (project: widget.projectUuid, environment: null),
        )
        .future);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(projectResourcesProvider(
      (project: widget.projectUuid, environment: null),
    ));
    return AsyncView(
      value: all,
      onRefresh: _refresh,
      builder: (context, list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.widgets_outlined,
            title: 'No resources yet',
          );
        }
        // Group by environment.
        final Map<String, List<Resource>> grouped = {};
        for (final r in list) {
          grouped.putIfAbsent(r.environmentName ?? 'Default', () => []).add(r);
        }
        final keys = grouped.keys.toList()..sort();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final env = keys[i];
              final rows = grouped[env]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Text(
                      env,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (var j = 0; j < rows.length; j++) ...[
                          ResourceCard(
                            resource: rows[j],
                            onTap: () => openResource(context, rows[j]),
                          ),
                          if (j != rows.length - 1)
                            const Divider(height: 1, indent: 56),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}