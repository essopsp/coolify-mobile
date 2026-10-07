import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/application.dart';
import '../../core/models/deployment.dart';
import '../../core/models/resource.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import '../../shared/widgets/status_chip.dart';
import '../detail_providers.dart';
import '../deployments/application_deployments_screen.dart';
import '../deployments/deployment_detail_screen.dart';
import '../deployments/deployments_provider.dart';
import '../deployments/widgets.dart';
import '../resources/widgets.dart';
import 'app_envs_tab.dart';
import 'app_logs_tab.dart';
import 'app_tasks_tab.dart';

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  const ApplicationDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState
    extends ConsumerState<ApplicationDetailScreen> {
  int _tab = 0;

  Future<void> _refresh() async {
    ref.invalidate(applicationProvider(widget.uuid));
    ref.invalidate(appDeploymentsProvider(widget.uuid));
    if (_tab == 1) ref.invalidate(appEnvVarsProvider(widget.uuid));
    if (_tab == 2) ref.invalidate(appLogsProvider((uuid: widget.uuid, service: null)));
    await Future.wait([
      ref.read(applicationProvider(widget.uuid).future),
      ref.read(appDeploymentsProvider(widget.uuid).future),
    ]);
  }

  Future<void> _action(String action) async {
    final app = ref.read(applicationProvider(widget.uuid)).value;
    if (app == null) return;
    switch (action) {
      case 'deploy':
        final dep = await performDeploy(
          context,
          ref,
          uuid: widget.uuid,
        );
        if (dep != null) {
          _openDeployment(dep);
        }
        await _refresh();
      default:
        await performControl(
          context,
          ref,
          type: ResourceType.application,
          uuid: widget.uuid,
          action: action,
        );
        await _refresh();
    }
  }

  void _openDeployment(String uuid) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => DeploymentDetailScreen(uuid: uuid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(applicationProvider(widget.uuid));
    final app = appAsync.value;
    final deployments = ref.watch(appDeploymentsProvider(widget.uuid));

    return Scaffold(
      appBar: AppBar(
        title: Text(app?.name ?? 'Application'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
        children: [
          if (app != null)
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _BarAction(
                    icon: Icons.play_circle_outline,
                    label: 'Start',
                    color: Colors.greenAccent,
                    onTap: () => _action('start'),
                  ),
                  _BarAction(
                    icon: Icons.restart_alt,
                    label: 'Restart',
                    color: Colors.amberAccent,
                    onTap: () => _action('restart'),
                  ),
                  _BarAction(
                    icon: Icons.rocket_launch_outlined,
                    label: 'Deploy',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => _action('deploy'),
                  ),
                  _BarAction(
                    icon: Icons.stop_circle_outlined,
                    label: 'Stop',
                    color: Colors.redAccent,
                    onTap: () => _action('stop'),
                  ),
                ],
              ),
            ),
          TabBar(
            onTap: (i) => setState(() => _tab = i),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Env'),
              Tab(text: 'Logs'),
              Tab(text: 'Tasks'),
            ],
          ),
          Expanded(
            child: switch (_tab) {
              0 => _OverviewTab(
                  appAsync: appAsync,
                  deployments: deployments,
                  uuid: widget.uuid,
                ),
              1 => EnvVarsTab(
                  resource: 'application',
                  uuid: widget.uuid,
                  envProvider: ref.watch(appEnvVarsProvider(widget.uuid)),
                ),
              2 => LogsTab(
                  logProvider: ref.watch(
                      appLogsProvider((uuid: widget.uuid, service: null))),
                  onRefresh: () async {
                    ref.invalidate(
                        appLogsProvider((uuid: widget.uuid, service: null)));
                  },
                ),
              _ => TasksTab(resource: 'application', uuid: widget.uuid),
            },
          ),
        ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.appAsync,
    required this.deployments,
    required this.uuid,
  });

  final AsyncValue<Application> appAsync;
  final AsyncValue<List<Deployment>> deployments;
  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<Application>(
      value: appAsync,
      builder: (context, app) {
        final status = app.parsedStatus;
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [StatusChip(status)]),
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (app.fqdn != null && app.fqdn!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text('Domains',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    InfoRow('FQDN', app.fqdn),
                  ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text('Build',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  InfoRow('Repository', app.gitRepository ?? app.sourceLabel),
                  if (app.gitBranch != null &&
                      app.gitBranch!.isNotEmpty &&
                      app.gitRepository != null)
                    InfoRow('Branch', app.gitBranch),
                  if (app.gitCommitSha != null)
                    InfoRow('Commit', app.gitCommitSha),
                  InfoRow('Build pack', app.buildPack ?? '—'),
                  if (app.dockerRegistryImageName != null)
                    InfoRow('Docker image', app.dockerRegistryImageName),
                  if (app.portsExposes != null) InfoRow('Ports', app.portsExposes),
                  if (app.portsMappings != null && app.portsMappings!.isNotEmpty)
                    InfoRow('Port mappings', app.portsMappings),
                  if (app.baseDirectory != null)
                    InfoRow('Base dir', app.baseDirectory),
                  if (app.publishDirectory != null)
                    InfoRow('Publish dir', app.publishDirectory),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (app.description != null && app.description!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(app.description!),
                ),
              ),
            const SectionHeader('Deployments'),
            if (deployments.isLoading && !deployments.hasValue)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (deployments.value?.isEmpty ?? true)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No deployments yet.',
                      style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              for (final d in deployments.value!.take(8))
                DeploymentTile(deployment: d),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ApplicationDeploymentsScreen(uuid: uuid),
                    ),
                  ),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('View full history'),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}