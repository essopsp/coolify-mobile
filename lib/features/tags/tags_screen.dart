import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/resource.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import '../projects/projects_provider.dart';
import '../resources/resources_provider.dart';
import '../resources/widgets.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  Future<void> _refresh() async {
    ref.invalidate(tagsProvider);
    ref.invalidate(resourcesProvider);
    await ref.read(tagsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);
    final resources = ref.watch(resourcesProvider).value ?? const [];
    final byTag = <String, List<Resource>>{};
    for (final r in resources) {
      for (final t in r.tags) {
        byTag.putIfAbsent(t, () => []).add(r);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: AsyncView<List<Tag>>(
        value: tags,
        onRefresh: _refresh,
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.sell_outlined,
              title: 'No tags',
              subtitle: 'Tag resources from the Coolify dashboard.',
            );
          }
          final chips = <String>{
            for (final t in list) if (t.name != null) t.name!,
            ...byTag.keys,
          }.toList()
            ..sort();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in chips)
                    Chip(
                      avatar: const Icon(Icons.sell_outlined, size: 16),
                      label: Text(
                        name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (byTag.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text('Tagged resources',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54)),
                ),
                for (final e in byTag.entries)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        child: Text(
                          e.key,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38),
                        ),
                      ),
                      for (final r in e.value)
                        ResourceCard(
                          resource: r,
                          onTap: () => openResource(context, r),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}