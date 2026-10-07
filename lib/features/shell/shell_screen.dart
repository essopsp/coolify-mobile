import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _index = 0;

  static const _tabs = ['/', '/resources', '/deployments', '/servers', '/settings'];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.rocket_launch_outlined,
    Icons.dns_outlined,
    Icons.settings_outlined,
  ];
  static const _active = [
    Icons.dashboard,
    Icons.inventory_2,
    Icons.rocket_launch,
    Icons.dns,
    Icons.settings,
  ];
  static const _labels = ['Home', 'Resources', 'Deploys', 'Servers', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) {
      if (t == '/') return location == '/';
      return location.startsWith(t);
    });
    _index = idx < 0 ? 0 : idx;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == _index) return;
          setState(() => _index = i);
          context.go(_tabs[i]);
        },
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_active[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}