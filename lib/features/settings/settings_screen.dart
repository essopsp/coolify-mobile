import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/team.dart';
import '../../core/providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/sections.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _refresh() async {
    ref.invalidate(currentTeamProvider);
    await ref.read(currentTeamProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(currentTeamProvider);
    final instance = ref.watch(instancesProvider).value?.active;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
        children: [
          if (instance != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.dns_outlined, color: Colors.cyanAccent),
                ),
                title: Text(instance.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  instance.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: const Text('active',
                    style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                onTap: () => context.push('/instances'),
              ),
            ),
          SectionHeader('Team'),
          AsyncView<Team?>(
            value: team,
            onRefresh: _refresh,
            builder: (context, t) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(t?.name ?? '(no team)'),
                subtitle: Text(t?.description ?? 'Connected via API token'),
              ),
            ),
          ),
          SectionHeader('General'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open,
                      color: Colors.orangeAccent),
                  title: const Text('Projects'),
                  subtitle: const Text('Browse projects and environments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/projects'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.sell_outlined, color: Colors.tealAccent),
                  title: const Text('Tags'),
                  subtitle: const Text('Tags assigned to resources'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tags'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined,
                      color: Colors.purpleAccent),
                  title: const Text('Audit log'),
                  subtitle: const Text('Recent team operations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/audit'),
                ),
              ],
            ),
          ),
          SectionHeader('Connection'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: Colors.greenAccent),
                  title: const Text('Add another instance'),
                  subtitle: const Text('Connect a second Coolify server'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/instances/new'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.list_alt,
                      color: Colors.lightBlueAccent),
                  title: const Text('Instance list'),
                  subtitle: const Text('Switch or remove connections'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/instances'),
                ),
              ],
            ),
          ),
          SectionHeader('About'),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.rocket_launch_outlined),
                  title: Text('App'),
                  subtitle: Text('Coolify Mobile'),
                ),
                ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('API'),
                  subtitle: Text('v1 REST · Bearer auth'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}