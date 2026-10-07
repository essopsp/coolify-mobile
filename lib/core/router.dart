import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/applications/application_detail_screen.dart';
import '../features/databases/database_detail_screen.dart';
import '../features/deployments/deployment_detail_screen.dart';
import '../features/deployments/deployments_screen.dart';
import '../features/deployments/application_deployments_screen.dart';
import '../features/instances/instance_edit_screen.dart';
import '../features/instances/instances_screen.dart';
import '../features/projects/project_detail_screen.dart';
import '../features/projects/environment_detail_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/resources/resources_screen.dart';
import '../features/servers/server_detail_screen.dart';
import '../features/servers/servers_screen.dart';
import '../features/services/service_detail_screen.dart';
import '../features/settings/audit_events_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/tags/tags_screen.dart';
import '../core/models/environment.dart';
import '../core/providers.dart';
import '../shared/widgets/sections.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final async = ref.read(instancesProvider);
      // Unknown until the store has loaded.
      if (async.isLoading) return null;
      final hasActive = async.value?.hasActive ?? false;
      final isGoingToInstances =
          state.uri.path == '/instances' ||
          state.uri.path.startsWith('/instances/');
      if (!hasActive && !isGoingToInstances) {
        return '/instances';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/instances',
        builder: (_, _) => const InstancesScreen(),
      ),
      GoRoute(
        path: '/instances/new',
        builder: (_, _) => const InstanceEditScreen(),
      ),
      GoRoute(
        path: '/instances/:id',
        builder: (_, state) =>
            InstanceEditScreen(editId: state.pathParameters['id']),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/resources',
            builder: (_, _) => const ResourcesScreen(),
          ),
          GoRoute(
            path: '/deployments',
            builder: (_, _) => const DeploymentsScreen(),
          ),
          GoRoute(
            path: '/servers',
            builder: (_, _) => const ServersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/applications/:uuid',
        builder: (_, state) => ApplicationDetailScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/applications/:uuid/deployments',
        builder: (_, state) => ApplicationDeploymentsScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/databases/:uuid',
        builder: (_, state) => DatabaseDetailScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/services/:uuid',
        builder: (_, state) => ServiceDetailScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/servers/:uuid',
        builder: (_, state) => ServerDetailScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/deployments/:uuid',
        builder: (_, state) => DeploymentDetailScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/projects',
        builder: (_, _) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/projects/:uuid',
        builder: (_, state) => ProjectDetailScreen(
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        path: '/projects/:uuid/env/:envid',
        builder: (_, state) => EnvironmentDetailScreen(
          environment: state.extra as Environment,
        ),
      ),
      GoRoute(
        path: '/tags',
        builder: (_, _) => const TagsScreen(),
      ),
      GoRoute(
        path: '/audit',
        builder: (_, _) => const AuditEventsScreen(),
      ),
      GoRoute(
        path: '/no-instance',
        builder: (_, _) => const EmptyState(
          icon: Icons.cloud_off,
          title: 'No active connection',
          subtitle: 'Add or select a Coolify instance in the connection list.',
        ),
      ),
    ],
  );
});