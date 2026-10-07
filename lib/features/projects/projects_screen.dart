import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/resource.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import 'projects_provider.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            onPressed: () async {
              ref.invalidate(projectsProvider);
              await ref.read(projectsProvider.future);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncView<List<Project>>(
        value: projects,
        onRefresh: () async {
          ref.invalidate(projectsProvider);
          await ref.read(projectsProvider.future);
        },
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open,
              title: 'No projects',
              subtitle: 'Create projects from the Coolify dashboard.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectsProvider);
              await ref.read(projectsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                final counts = p.counts;
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.folder, color: Colors.orangeAccent),
                    ),
                    title: Text(p.name ?? '(unnamed)',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [
                        if (counts != null)
                          '${counts.applications} apps · '
                          '${counts.services} services · '
                          '${counts.databases} dbs'
                        else
                          '${p.environments.length} environment(s)',
                      ].join(''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/projects/${p.uuid}'),
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