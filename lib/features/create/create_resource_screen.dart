import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/github_app.dart';
import '../../core/models/resource.dart';
import '../../core/models/server.dart';
import '../../core/models/service_template.dart';
import '../../core/providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';
import '../projects/projects_provider.dart';
import '../resources/resources_provider.dart';
import 'create_provider.dart';

const _buildPacks = ['nixpacks', 'railpack', 'static', 'dockerfile', 'dockercompose'];

class CreateResourceScreen extends ConsumerStatefulWidget {
  const CreateResourceScreen({super.key});

  @override
  ConsumerState<CreateResourceScreen> createState() => _CreateResourceScreenState();
}

class _CreateResourceScreenState extends ConsumerState<CreateResourceScreen> {
  int _tab = 0;

  String? _projectUuid;
  String? _environmentUuid;
  String? _serverUuid;
  String _ghAppUuid = '';

  String _repoQuery = '';
  String _serviceQuery = '';

  bool get _ready =>
      _projectUuid != null && _environmentUuid != null && _serverUuid != null;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final servers = ref.watch(serversProvider);
    final ghApps = ref.watch(githubAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New resource'),
        actions: [
          IconButton(
            onPressed: () async {
              ref.invalidate(projectsProvider);
              ref.invalidate(serversProvider);
              ref.invalidate(githubAppsProvider);
              if (_ghAppUuid.isNotEmpty) {
                ref.invalidate(githubReposProvider(_ghAppUuid));
              }
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          AsyncView<List<Project>>(
            value: projects,
            onRefresh: () async {
              ref.invalidate(projectsProvider);
              await ref.read(projectsProvider.future);
            },
            builder: (context, list) => _targetPickers(list, servers.value),
          ),
          const SizedBox(height: 8),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'What do you want to create?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.code),
                  label: Text('From GitHub'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.widgets_outlined),
                  label: Text('One-click service'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 8),
          switch (_tab) {
            0 => _githubTab(ghApps),
            _ => _servicesTab(),
          },
        ],
      ),
    );
  }

  // ── Project / environment / server pickers ─────────────────────────────────
  Widget _targetPickers(List<Project> projects, List<Server>? servers) {
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No projects yet. Create a project in the Coolify dashboard first.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    _syncDefaults(projects, servers ?? const []);
    final serverList = servers ?? const <Server>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Project'),
          DropdownButtonFormField<String>(
            initialValue: _projectUuid,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final p in projects)
                DropdownMenuItem(value: p.uuid!, child: Text(p.name ?? '(unnamed)')),
            ],
            onChanged: (v) => setState(() {
              _projectUuid = v;
              _environmentUuid = null;
            }),
          ),
          const SizedBox(height: 12),
          _label('Environment'),
          _environmentPicker(),
          const SizedBox(height: 12),
          _label('Server'),
          DropdownButtonFormField<String>(
            initialValue: _serverUuid,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final s in serverList)
                DropdownMenuItem(value: s.uuid!, child: Text(s.name ?? s.hostLabel)),
            ],
            onChanged: (v) => setState(() => _serverUuid = v),
          ),
        ],
      ),
    );
  }

  void _syncDefaults(List<Project> projects, List<Server> servers) {
    if (_projectUuid == null || !projects.any((p) => p.uuid == _projectUuid)) {
      _projectUuid = projects.first.uuid;
      _environmentUuid = null;
    }
    if (servers.isNotEmpty &&
        (_serverUuid == null || !servers.any((s) => s.uuid == _serverUuid))) {
      _serverUuid = servers.first.uuid;
    }
  }

  /// Environments are not part of `GET /projects`; fetch the selected
  /// project's detail to obtain them.
  Widget _environmentPicker() {
    return Consumer(
      builder: (context, ref, _) {
        final full = ref.watch(projectProvider(_projectUuid!));
        return full.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (e, _) => _errorCard(e),
          data: (project) {
            final envs = project.environments;
            if (envs.isEmpty) {
              return const Text(
                'This project has no environments.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              );
            }
            if (_environmentUuid == null ||
                !envs.any((e) => e.uuid == _environmentUuid)) {
              _environmentUuid = envs.first.uuid;
            }
            return InputDecorator(
              decoration: const InputDecoration(isDense: true),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: _environmentUuid,
                  items: [
                    for (final e in envs)
                      DropdownMenuItem(
                        value: e.uuid,
                        child: Text(e.name ?? '(unnamed)'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _environmentUuid = v),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── GitHub tab ─────────────────────────────────────────────────────────────
  Widget _githubTab(AsyncValue<List<GithubApp>> ghApps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ghApps.when(
          data: (apps) {
            if (_ghAppUuid.isEmpty && apps.isNotEmpty) _ghAppUuid = apps.first.uuid!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('GitHub app'),
                  if (apps.isEmpty)
                    const Text(
                      'No GitHub Apps connected to this Coolify instance. Add one in the Coolify dashboard first.',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _ghAppUuid,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: [
                        for (final a in apps)
                          DropdownMenuItem(
                            value: a.uuid!,
                            child: Text(a.name ?? '(unnamed)'),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _ghAppUuid = v ?? _ghAppUuid;
                        _repoQuery = '';
                      }),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => _errorCard(e),
        ),
        if (_ghAppUuid.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _repoQuery = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search repositories…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _githubRepoList(),
        ],
      ],
    );
  }

  Widget _githubRepoList() {
    final repos = ref.watch(githubReposProvider(_ghAppUuid));
    return AsyncView(
      value: repos,
      onRefresh: () async {
        ref.invalidate(githubReposProvider(_ghAppUuid));
        await ref.read(githubReposProvider(_ghAppUuid).future);
      },
      builder: (context, list) {
        final filtered = list.where((r) {
          if (_repoQuery.isEmpty) return true;
          return (r.fullName?.toLowerCase().contains(_repoQuery) ?? false) ||
              (r.name?.toLowerCase().contains(_repoQuery) ?? false);
        }).toList();
        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No repositories',
            subtitle: 'Nothing matches your search.',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final repo = filtered[i];
            return Card(
              child: ListTile(
                leading: repo.isPrivate == true
                    ? const Icon(Icons.lock_outline)
                    : const Icon(Icons.public),
                title: Text(repo.fullName ?? repo.name ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${repo.isPrivate == true ? 'Private · ' : ''}${repo.defaultBranch ?? 'main'}'),
                onTap: () => _openRepoCreate(repo),
              ),
            );
          },
        );
      },
    );
  }

  void _openRepoCreate(GithubRepository repo) {
    if (!_ready) {
      _notReady();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RepoCreateSheet(
        repo: repo,
        appUuid: _ghAppUuid,
        projectUuid: _projectUuid!,
        environmentUuid: _environmentUuid!,
        serverUuid: _serverUuid!,
        onCreated: (uuid, name) => _onCreated(uuid, name, isService: false),
      ),
    );
  }

  // ── Services tab ───────────────────────────────────────────────────────────
  Widget _servicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _serviceQuery = v.toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search one-click services… (n8n, gitea, immich…)',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _serviceList(),
      ],
    );
  }

  Widget _serviceList() {
    final filtered = ServiceTemplate.catalog.where((t) {
      if (_serviceQuery.isEmpty) return true;
      return t.type.contains(_serviceQuery) ||
          t.slogan.toLowerCase().contains(_serviceQuery);
    }).toList();
    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.widgets_outlined,
        title: 'No services found',
        subtitle: 'Nothing matches your search.',
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final t = filtered[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.widgets_outlined),
            title: Text(t.type,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: t.slogan.isEmpty
                ? null
                : Text(t.slogan, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => _openServiceCreate(t),
          ),
        );
      },
    );
  }

  void _openServiceCreate(ServiceTemplate t) {
    if (!_ready) {
      _notReady();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ServiceCreateSheet(
        template: t,
        projectUuid: _projectUuid!,
        environmentUuid: _environmentUuid!,
        serverUuid: _serverUuid!,
        onCreated: (uuid, name) => _onCreated(uuid, name, isService: true),
      ),
    );
  }

  void _onCreated(String uuid, String name, {required bool isService}) {
    ref.invalidate(resourcesProvider);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('$name created')));
    context.push(isService ? '/services/$uuid' : '/applications/$uuid');
  }

  void _notReady() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select project, environment and server first.')),
    );
  }

  // ── misc ───────────────────────────────────────────────────────────────────
  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          s,
          style: const TextStyle(
              fontSize: 12, color: Colors.white54, letterSpacing: 0.3),
        ),
      );

  Widget _errorCard(Object? error) {
    final msg = error is ApiException ? error.message : '$error';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GitHub create sheet ───────────────────────────────────────────────────────
class _RepoCreateSheet extends ConsumerStatefulWidget {
  const _RepoCreateSheet({
    required this.repo,
    required this.appUuid,
    required this.projectUuid,
    required this.environmentUuid,
    required this.serverUuid,
    required this.onCreated,
  });

  final GithubRepository repo;
  final String appUuid;
  final String projectUuid;
  final String environmentUuid;
  final String serverUuid;
  final void Function(String uuid, String name) onCreated;

  @override
  ConsumerState<_RepoCreateSheet> createState() => _RepoCreateSheetState();
}

class _RepoCreateSheetState extends ConsumerState<_RepoCreateSheet> {
  late final TextEditingController _name;
  String _branch = '';
  String _buildPack = 'nixpacks';
  bool _instant = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.repo.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(githubBranchesProvider((
      appUuid: widget.appUuid,
      owner: widget.repo.owner,
      repo: widget.repo.repo,
    )));
    final defaultBranch = widget.repo.defaultBranch ?? 'main';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create from GitHub',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.repo.fullName ?? '',
                style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name', isDense: true),
            ),
            const SizedBox(height: 12),
            branches.when(
              data: (list) {
                final names = list.map((b) => b.name ?? '').where((n) => n.isNotEmpty).toList();
                if (_branch.isEmpty) {
                  _branch = names.contains(defaultBranch)
                      ? defaultBranch
                      : (names.isNotEmpty ? names.first : '');
                }
                if (names.isEmpty) {
                  return const Text('No branches found',
                      style: TextStyle(color: Colors.white54));
                }
                return DropdownButtonFormField<String>(
                  key: ValueKey('branch-$_branch'),
                  initialValue: _branch,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Branch', isDense: true),
                  items: [
                    for (final n in names)
                      DropdownMenuItem(value: n, child: Text(n)),
                  ],
                  onChanged: (v) => setState(() => _branch = v ?? _branch),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _buildPack,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Build pack', isDense: true),
              items: [
                for (final b in _buildPacks)
                  DropdownMenuItem(value: b, child: Text(b)),
              ],
              onChanged: (v) => setState(() => _buildPack = v ?? _buildPack),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deploy immediately'),
              value: _instant,
              onChanged: (v) => setState(() => _instant = v),
            ),
            const SizedBox(height: 8),
            _busy
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton.icon(
                    onPressed: () => _create(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_branch.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a branch first.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final uuid = await api.createApplicationFromGithub(
        projectUuid: widget.projectUuid,
        environmentUuid: widget.environmentUuid,
        serverUuid: widget.serverUuid,
        githubAppUuid: widget.appUuid,
        gitRepository: widget.repo.fullName ?? '',
        gitBranch: _branch,
        buildPack: _buildPack,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        instantDeploy: _instant,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(
        uuid,
        _name.text.trim().isEmpty ? widget.repo.name ?? '' : _name.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

// ── Service create sheet ──────────────────────────────────────────────────────
class _ServiceCreateSheet extends ConsumerStatefulWidget {
  const _ServiceCreateSheet({
    required this.template,
    required this.projectUuid,
    required this.environmentUuid,
    required this.serverUuid,
    required this.onCreated,
  });

  final ServiceTemplate template;
  final String projectUuid;
  final String environmentUuid;
  final String serverUuid;
  final void Function(String uuid, String name) onCreated;

  @override
  ConsumerState<_ServiceCreateSheet> createState() => _ServiceCreateSheetState();
}

class _ServiceCreateSheetState extends ConsumerState<_ServiceCreateSheet> {
  late final TextEditingController _name;
  bool _instant = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.template.type);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.template.type, style: Theme.of(context).textTheme.titleLarge),
            if (widget.template.slogan.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(widget.template.slogan,
                  style: const TextStyle(color: Colors.white54)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name', isDense: true),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deploy immediately'),
              value: _instant,
              onChanged: (v) => setState(() => _instant = v),
            ),
            const SizedBox(height: 8),
            _busy
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton.icon(
                    onPressed: () => _create(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final uuid = await api.createService(
        type: widget.template.type,
        projectUuid: widget.projectUuid,
        environmentUuid: widget.environmentUuid,
        serverUuid: widget.serverUuid,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        instantDeploy: _instant,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(
        uuid,
        _name.text.trim().isEmpty ? widget.template.type : _name.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}