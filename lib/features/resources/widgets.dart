import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/application.dart';
import '../../core/models/database.dart';
import '../../core/models/resource.dart';
import '../../core/models/server.dart';
import '../../core/models/service.dart';
import '../../core/providers.dart';
import '../../shared/widgets/confirm.dart';
import '../../shared/widgets/status_chip.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({super.key, required this.resource, this.onTap});

  final Resource resource;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = resource.type;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == ResourceType.application
              ? Colors.indigo.withValues(alpha: 0.25)
              : type == ResourceType.database
                  ? Colors.teal.withValues(alpha: 0.25)
                  : Colors.orange.withValues(alpha: 0.25),
          child: Icon(resourceTypeIcon(type),
              color: type == ResourceType.application
                  ? Colors.indigo.shade200
                  : type == ResourceType.database
                      ? Colors.teal.shade200
                      : Colors.orange.shade200),
        ),
        title: Text(
          resource.name ?? '(unnamed)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (resource.projectName != null) resource.projectName!,
            if (resource.environmentName != null)
              'env: ${resource.environmentName}',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusChip(resource.parsedStatus, compact: true),
        onTap: onTap,
      ),
    );
  }
}

/// Routes to the correct detail screen for a resource.
void openResource(BuildContext context, Resource r) {
  switch (r.type) {
    case ResourceType.application:
      context.push('/applications/${r.uuid}');
    case ResourceType.service:
      context.push('/services/${r.uuid}');
    case ResourceType.database:
    case ResourceType.databaseProxy:
      context.push('/databases/${r.uuid}');
    case ResourceType.unknown:
      break;
  }
}

class ResourceDetailModel {
  const ResourceDetailModel({
    this.type = ResourceType.unknown,
    this.uuid,
    this.name,
    this.status,
    this.application,
    this.database,
    this.service,
    this.server,
  });

  final ResourceType type;
  final String? uuid;
  final String? name;
  final String? status;
  final Application? application;
  final Database? database;
  final Service? service;
  final Server? server;
}

/// Bottom sheet with Start / Stop / Restart / Deploy actions.
/// Returns the new deployment uuid after a deploy/start, if any.
Future<String?> showResourceActionSheet(
  BuildContext context, {
  required ResourceType type,
  required String uuid,
  String statusLabel = '',
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(resourceTypeIcon(type), color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusLabel.isEmpty ? 'Resource actions' : statusLabel,
                    style: Theme.of(ctx).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ActionItem(
            icon: Icons.play_circle_outline,
            label: 'Start',
            color: Colors.greenAccent,
            onTap: () => Navigator.pop(ctx, 'start'),
          ),
          _ActionItem(
            icon: Icons.restart_alt,
            label: 'Restart',
            color: Colors.amberAccent,
            onTap: () => Navigator.pop(ctx, 'restart'),
          ),
          _ActionItem(
            icon: Icons.rocket_launch_outlined,
            label: 'Deploy / rebuild',
            color: scheme.primary,
            onTap: () => Navigator.pop(ctx, 'deploy'),
          ),
          _ActionItem(
            icon: Icons.stop_circle_outlined,
            label: 'Stop',
            color: scheme.error,
            destructive: true,
            onTap: () => Navigator.pop(ctx, 'stop'),
          ),
        ],
      ),
    ),
  );
  return result;
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: onTap,
    );
  }
}

String resourceTypeApiName(ResourceType t) => switch (t) {
      ResourceType.application => 'application',
      ResourceType.service => 'service',
      ResourceType.database || ResourceType.databaseProxy => 'database',
      ResourceType.unknown => 'application',
    };

/// Runs start/stop/restart for a resource type via POST /{resource}/{uuid}/{action}.
Future<void> performControl(
  BuildContext context,
  WidgetRef ref, {
  required ResourceType type,
  required String uuid,
  required String action,
}) async {
  if (action == 'stop') {
    final ok = await confirmAction(
      context,
      title: 'Stop resource?',
      message: 'This stops the container and makes the resource unavailable.',
      confirmLabel: 'Stop',
      destructive: true,
    );
    if (!ok) return;
  }
  if (!context.mounted) return;
  final resource = resourceTypeApiName(type);
  final successLabel = switch (action) {
    'start' => 'Start request sent.',
    'restart' => 'Restart request sent.',
    _ => 'Stop request sent.',
  };
  await showBusy(
    context,
    action: () async {
      await ref
          .read(apiProvider)
          .control(resource, uuid, action);
    },
    successMessage: successLabel,
    busyLabel: action == 'start' ? 'Starting…' : 'Sending request…',
  );
}

/// Runs `coolify deploy` on a resource with an optional force rebuild toggle.
Future<String?> performDeploy(
  BuildContext context,
  WidgetRef ref, {
  required String uuid,
}) async {
  final force = await showDialog<bool>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Deploy'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Deploy (use cache)'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Force rebuild (no cache)'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (force == null) return null;
  if (!context.mounted) return null;

  String? deploymentUuid;
  final ok = await showBusy(
    context,
    action: () async {
      final results = await ref.read(apiProvider).deploy(uuid, force: force);
      deploymentUuid = results.isNotEmpty ? results.first.deploymentUuid : null;
    },
    successMessage: force ? 'Rebuild queued.' : 'Deployment queued.',
    busyLabel: 'Queuing deployment…',
  );
  return ok ? deploymentUuid : null;
}