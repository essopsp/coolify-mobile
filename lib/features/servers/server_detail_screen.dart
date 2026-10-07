import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/server.dart';
import '../../core/providers.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/confirm.dart';
import '../../shared/widgets/sections.dart';
import '../detail_providers.dart';

class ServerDetailScreen extends ConsumerStatefulWidget {
  const ServerDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<ServerDetailScreen> createState() =>
      _ServerDetailScreenState();
}

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen> {
  int _tab = 0;

  Future<void> _refresh() async {
    ref.invalidate(serverProvider(widget.uuid));
    ref.invalidate(serverResourcesProvider(widget.uuid));
    ref.invalidate(serverDomainsProvider(widget.uuid));
    ref.invalidate(serverCleanupProvider(widget.uuid));
    await Future.wait([
      ref.read(serverProvider(widget.uuid).future),
      ref.read(serverResourcesProvider(widget.uuid).future),
    ]);
  }

  Future<void> _validate() async {
    await showBusy(
      context,
      action: () => ref.read(apiProvider).validateServer(widget.uuid),
      successMessage: 'Validation requested. It may take a minute.',
      busyLabel: 'Validating…',
    );
    await _refresh();
  }

  Future<void> _restartProxy() async {
    final ok = await confirmAction(
      context,
      title: 'Restart proxy?',
      message: 'Restarts the reverse proxy container. Brief downtime expected.',
      confirmLabel: 'Restart proxy',
    );
    if (!ok) return;
    if (!mounted) return;
    await showBusy(
      context,
      action: () => ref.read(apiProvider).restartServerProxy(widget.uuid),
      successMessage: 'Proxy restart queued.',
      busyLabel: 'Restarting proxy…',
    );
    await _refresh();
  }

  Future<void> _dockerCleanup() async {
    final ok = await confirmAction(
      context,
      title: 'Run Docker cleanup?',
      message: 'Removes unused containers, images, volumes and networks.',
      confirmLabel: 'Clean up',
      destructive: true,
    );
    if (!ok) return;
    if (!mounted) return;
    await showBusy(
      context,
      action: () => ref.read(apiProvider).runDockerCleanup(widget.uuid),
      successMessage: 'Docker cleanup scheduled.',
      busyLabel: 'Cleaning…',
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverProvider(widget.uuid));
    return Scaffold(
      appBar: AppBar(title: const Text('Server'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ]),
      body: AsyncView(
        value: server,
        onRefresh: _refresh,
        builder: (context, s) {
          return DefaultTabController(
            length: 4,
            child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      (s.isReachable ?? false)
                          ? Icons.dns
                          : Icons.dns_outlined,
                      color: (s.isReachable ?? false)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (s.isReachable ?? false) ? 'Reachable' : 'Unreachable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _validate,
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text('Validate'),
                    ),
                  ],
                ),
              ),
              TabBar(
                onTap: (i) => setState(() => _tab = i),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Resources'),
                  Tab(text: 'Domains'),
                  Tab(text: 'Cleanup'),
                ],
              ),
              Expanded(
                child: switch (_tab) {
                  0 => _ServerOverview(
                      server: s,
                      onRestartProxy: _restartProxy,
                    ),
                  1 => _ServerResources(uuid: widget.uuid, onRefresh: _refresh),
                  2 => _ServerDomains(uuid: widget.uuid),
                  _ => _CleanupTab(uuid: widget.uuid, onRun: _dockerCleanup),
                },
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

class _ServerOverview extends StatelessWidget {
  const _ServerOverview({
    required this.server,
    required this.onRestartProxy,
  });

  final Server server;
  final VoidCallback onRestartProxy;

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
                child: Text('Connection',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('Name', server.name),
              InfoRow('Address', server.hostLabel),
              InfoRow('IP', server.ip),
              InfoRow('User', server.user),
              InfoRow('Timeout', server.connectionTimeout?.toString()),
              if (server.isValidating ?? false) const InfoRow('Status', 'Validating…'),
              if (server.description != null && server.description!.isNotEmpty)
                InfoRow('Description', server.description),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Proxy',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('Type', server.proxy?.type ?? '—'),
              InfoRow('Status', server.proxy?.status ?? '—'),
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: onRestartProxy,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Restart proxy'),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Settings',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('Docker', server.settings?.dockerVersion ?? '—'),
              InfoRow('Timezone', server.settings?.serverTimezone ?? 'UTC'),
              InfoRow('Concurrent builds', server.settings?.concurrentBuilds?.toString()),
              InfoRow('Wildcard domain', server.settings?.wildcardDomain),
              InfoRow('Swarm manager', _yn(server.settings?.isSwarmManager)),
              InfoRow('Build server', _yn(server.settings?.isBuildServer)),
              InfoRow('Cloudflare tunnel', _yn(server.settings?.isCloudflareTunnel)),
              InfoRow('SSH terminal', _yn(server.settings?.isTerminalEnabled)),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Metadata',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              InfoRow('UUID', server.uuid),
              InfoRow('Created', formatDateTime(server.createdAt)),
              InfoRow('Updated', formatDateTime(server.updatedAt)),
            ],
          ),
        ),
      ],
    );
  }

  static String _yn(bool? v) => v == null ? '—' : (v ? 'Yes' : 'No');
}

class _ServerResources extends ConsumerWidget {
  const _ServerResources({required this.uuid, required this.onRefresh});

  final String uuid;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(serverResourcesProvider(uuid));
    return AsyncView(
      value: resources,
      onRefresh: onRefresh,
      builder: (context, list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('No resources on this server.',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final r = list[i];
            final status = r.parsedStatus;
            return Card(
              child: ListTile(
                leading: Icon(status.icon, color: status.color(context)),
                title: Text(r.name ?? r.uuid ?? '(unnamed)',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${r.type ?? '—'}   ${status.label}'),
                onTap: () {
                  if (r.type == 'application') {
                    context.push('/applications/${r.uuid}');
                  } else if (r.type == 'service') {
                    context.push('/services/${r.uuid}');
                  } else if (r.type == 'database') {
                    context.push('/databases/${r.uuid}');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ServerDomains extends ConsumerWidget {
  const _ServerDomains({required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domains = ref.watch(serverDomainsProvider(uuid));
    return AsyncView(
      value: domains,
      builder: (context, list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('No domains configured.',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final d = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(d.resourceName ?? '—',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    if (d.resourceType != null) d.resourceType!,
                    ...?d.domains,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CleanupTab extends ConsumerWidget {
  const _CleanupTab({required this.uuid, required this.onRun});

  final String uuid;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanup = ref.watch(serverCleanupProvider(uuid));
        final data = cleanup.value ?? const <String, dynamic>{};
        final rows = <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Docker cleanup',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ];
        if (data.isEmpty) {
          rows.add(const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('No data returned for this server yet.',
                style: TextStyle(color: Colors.white54)),
          ));
        } else if (data.containsKey('containers') ||
            data.containsKey('images')) {
          rows.addAll([
            InfoRow('Containers', _cleanupValue(data['containers'])),
            InfoRow('Images', _cleanupValue(data['images'])),
            InfoRow('Networks', _cleanupValue(data['networks'])),
            InfoRow('Volumes', _cleanupValue(data['volumes'])),
          ]);
        } else {
          for (final entry in data.entries) {
            rows.add(InfoRow(entry.key, _cleanupValue(entry.value)));
          }
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: onRun,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Run cleanup now'),
            ),
          ),
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows,
              ),
            ),
          ],
        );
  }
}
String _cleanupValue(dynamic v) {
  if (v == null) return '…';
  if (v is List) return '${v.length} items';
  if (v is Map) return '${v.length} entries';
  return v.toString();
}
