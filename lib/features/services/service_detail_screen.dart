import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/resource.dart';
import '../../core/models/service.dart';
import '../../core/providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/confirm.dart';
import '../../shared/widgets/sections.dart';
import '../../shared/widgets/status_chip.dart';
import '../applications/app_tasks_tab.dart';
import '../detail_providers.dart';
import '../resources/widgets.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  int _tab = 0;

  Future<void> _refresh() async {
    ref.invalidate(serviceProvider(widget.uuid));
    ref.invalidate(serviceAppsProvider(widget.uuid));
    ref.invalidate(serviceDbsProvider(widget.uuid));
    await Future.wait([
      ref.read(serviceProvider(widget.uuid).future),
      ref.read(serviceAppsProvider(widget.uuid).future),
      ref.read(serviceDbsProvider(widget.uuid).future),
    ]);
  }

  Future<void> _action(String action) async {
    await performControl(
      context,
      ref,
      type: ResourceType.service,
      uuid: widget.uuid,
      action: action,
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(serviceProvider(widget.uuid));
    final apps = ref.watch(serviceAppsProvider(widget.uuid));
    final dbs = ref.watch(serviceDbsProvider(widget.uuid));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Service'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ]),
      body: AsyncView(
        value: svc,
        onRefresh: _refresh,
        builder: (context, s) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    StatusChip(s.parsedStatus),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline,
                          color: Colors.greenAccent),
                      tooltip: 'Start',
                      onPressed: () => _action('start'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.restart_alt,
                          color: Colors.amberAccent),
                      tooltip: 'Restart',
                      onPressed: () => _action('restart'),
                    ),
                    IconButton(
                      icon: Icon(Icons.stop_circle_outlined,
                          color: scheme.error),
                      tooltip: 'Stop',
                      onPressed: () => _action('stop'),
                    ),
                  ],
                ),
              ),
              TabBar(
                onTap: (i) => setState(() => _tab = i),
                tabs: const [
                  Tab(text: 'Containers'),
                  Tab(text: 'Applications'),
                  Tab(text: 'Databases'),
                  Tab(text: 'Tasks'),
                ],
              ),
              Expanded(
                child: switch (_tab) {
                  0 => _ContainersOverview(
                      service: s,
                      appCount: apps.value?.length ?? 0,
                      dbCount: dbs.value?.length ?? 0,
                    ),
                  1 => _ServiceAppsList(
                      apps: apps,
                      serviceUuid: widget.uuid,
                      onRefresh: _refresh,
                    ),
                  2 => _ServiceDbsList(dbs: dbs, serviceUuid: widget.uuid),
                  _ => TasksTab(resource: 'service', uuid: widget.uuid),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContainersOverview extends StatelessWidget {
  const _ContainersOverview({
    required this.service,
    required this.appCount,
    required this.dbCount,
  });

  final Service service;
  final int appCount;
  final int dbCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Service',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('Name', service.name),
              if (service.fqdn != null && service.fqdn!.isNotEmpty)
                InfoRow('Domain', service.fqdn),
              InfoRow('Applications', '$appCount'),
              InfoRow('Databases', '$dbCount'),
              InfoRow('UUID', service.uuid),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceAppsList extends ConsumerStatefulWidget {
  const _ServiceAppsList({
    required this.apps,
    required this.serviceUuid,
    required this.onRefresh,
  });

  final AsyncValue<List<ServiceApp>> apps;
  final String serviceUuid;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_ServiceAppsList> createState() => _ServiceAppsListState();
}

class _ServiceAppsListState extends ConsumerState<_ServiceAppsList> {
  Future<void> _control(String appUuid, String action) async {
    await showBusy(
      context,
      action: () => ref
          .read(apiProvider)
          .serviceAppControl(widget.serviceUuid, appUuid, action),
      successMessage: '${action[0].toUpperCase()}${action.substring(1)} request sent.',
      busyLabel: 'Sending…',
    );
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: widget.apps,
      onRefresh: widget.onRefresh,
      builder: (context, list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.web_asset,
            title: 'No applications in this service',
          );
        }
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final app = list[i];
              final status = app.parsedStatus;
              return Card(
                child: ListTile(
                  leading: Icon(
                    status.icon,
                    color: status.color(context),
                  ),
                  title: Text(app.name ?? '(unnamed)',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (app.fqdn != null)
                        Text(app.fqdn!,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(status.label,
                          style: TextStyle(color: status.color(context), fontSize: 11)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline,
                            color: Colors.greenAccent),
                        tooltip: 'Start',
                        onPressed: () => _control(app.uuid!, 'start'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop_circle_outlined,
                            color: Colors.redAccent),
                        tooltip: 'Stop',
                        onPressed: () => _control(app.uuid!, 'stop'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ServiceDbsList extends ConsumerWidget {
  const _ServiceDbsList({required this.dbs, required this.serviceUuid});

  final AsyncValue<List<ServiceDatabase>> dbs;
  final String serviceUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: dbs,
      builder: (context, list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.storage,
            title: 'No databases in this service',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final db = list[i];
            final status = db.parsedStatus;
            return Card(
              child: ListTile(
                leading: Icon(status.icon, color: status.color(context)),
                title: Text(db.name ?? '(unnamed)'),
                subtitle: Text('${db.image ?? '—'} · ${status.label}'),
                trailing: StatusChip(status, compact: true),
              ),
            );
          },
        );
      },
    );
  }
}