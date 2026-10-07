import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/deployment.dart';
import '../../core/utils/format.dart';
import '../../core/utils/status.dart';

class DeploymentTile extends StatelessWidget {
  const DeploymentTile({super.key, required this.deployment, this.onTap});

  final Deployment deployment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = deployment.parsedStatus;
    final color = status.color(context);
    return Card(
      child: ListTile(
        leading: status.isActive
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(status.icon, color: color),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deployment.applicationName ?? deployment.applicationId?.toString() ?? 'Deployment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              status.label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deployment.commitMessage != null &&
                deployment.commitMessage!.isNotEmpty)
              Text(
                deployment.commitMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              [
                if (deployment.commit != null &&
                    deployment.commit!.isNotEmpty)
                  deployment.commit!.length > 10
                      ? deployment.commit!.substring(0, 10)
                      : deployment.commit!,
                '${timeAgo(deployment.createdAt)} · ${truncateMiddle(deployment.deploymentUuid ?? '', 14)}',
              ].join('  '),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap ??
            () => context.push('/deployments/${deployment.deploymentUuid}'),
      ),
    );
  }
}

class DeploymentLogView extends StatelessWidget {
  const DeploymentLogView({super.key, required this.logs});

  final String logs;

  @override
  Widget build(BuildContext context) {
    if (logs.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No log output yet.'),
        ),
      );
    }
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          logs,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
            color: Color(0xFFD8E1EC),
          ),
        ),
      ),
    );
  }
}

String deploymentProgressLabel(ResourceStatus s) => switch (s.base) {
      'queued' => 'Queued',
      'in_progress' || 'building' => 'In progress',
      'finished' => 'Finished',
      'failed' => 'Failed',
      'cancelled' || 'cancelled-by-user' => 'Cancelled',
      _ => s.label,
    };