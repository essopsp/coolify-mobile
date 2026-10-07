import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/resource.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import 'resources_provider.dart';
import 'widgets.dart';

enum _Filter { all, apps, databases, services }

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key, this.projectUuid, this.environmentUuid});

  final String? projectUuid;
  final String? environmentUuid;

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  Future<void> _refresh() async {
    ref.invalidate(resourcesProvider);
    await ref.read(resourcesProvider.future);
  }

  List<Resource> _apply(List<Resource> all) {
    var list = all;
    switch (_filter) {
      case _Filter.apps:
        list = list.where((r) => r.type == ResourceType.application).toList();
      case _Filter.databases:
        list = list.where((r) => r.type == ResourceType.database || r.type == ResourceType.databaseProxy).toList();
      case _Filter.services:
        list = list.where((r) => r.type == ResourceType.service).toList();
      case _Filter.all:
        break;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((r) =>
              (r.name?.toLowerCase().contains(q) ?? false) ||
              (r.uuid?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    list.sort((a, b) =>
        (a.parsedStatus.isRunning ? 0 : 1) - (b.parsedStatus.isRunning ? 0 : 1));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final resources = ref.watch(resourcesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'Search by name or UUID…',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.all, label: Text('All')),
                ButtonSegment(value: _Filter.apps, label: Text('Apps')),
                ButtonSegment(value: _Filter.databases, label: Text('Databases')),
                ButtonSegment(value: _Filter.services, label: Text('Services')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: AsyncView(
              value: resources,
              onRefresh: _refresh,
              builder: (context, list) {
                final filtered = _apply(list);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No resources found',
                    subtitle: 'Nothing matches the current filter.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final r = filtered[i];
                      return ResourceCard(
                        resource: r,
                        onTap: () => openResource(context, r),
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