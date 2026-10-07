import 'package:flutter/material.dart';

/// Parses Coolify resource/deployment status strings like
/// `running:healthy`, `exited:unhealthy`, `building`, `queued`, ...
class ResourceStatus {
  const ResourceStatus._(this.base, this.sub);

  final String base;
  final String? sub;

  factory ResourceStatus.parse(String? raw) {
    if (raw == null || raw.isEmpty) return const ResourceStatus._('unknown', null);
    final parts = raw.split(':');
    return ResourceStatus._(parts.first, parts.length > 1 ? parts[1] : null);
  }

  bool get isRunning => base == 'running';
  bool get isExited => base == 'exited' || base == 'stopped';
  bool get isDeploying =>
      base == 'building' || base == 'queued' || base == 'in_progress' || base == 'starting';
  bool get isFailed => base == 'failed';
  bool get isFinished => base == 'finished';
  bool get isCanceled => base == 'cancelled' || base == 'cancelled-by-user';
  bool get isUnhealthy => sub == 'unhealthy' || sub == 'error' || sub == 'failed';
  bool get isActive => isRunning || isDeploying;

  Color color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isFailed || isUnhealthy && isExited == false && !isRunning) return Colors.redAccent;
    if (isUnhealthy && isRunning) return Colors.orangeAccent;
    if (isRunning) return Colors.greenAccent;
    if (isDeploying) return Colors.amberAccent;
    if (isFinished) return Colors.lightBlueAccent;
    if (isCanceled) return Colors.grey;
    if (isExited) return Colors.grey.shade500;
    return scheme.outline;
  }

  IconData get icon {
    if (isFailed) return Icons.error_outline;
    if (isRunning && isUnhealthy) return Icons.warning_amber_rounded;
    if (isRunning) return Icons.play_circle_filled;
    if (isDeploying) return Icons.sync;
    if (isFinished) return Icons.check_circle_outline;
    if (isCanceled) return Icons.cancel_outlined;
    if (isExited) return Icons.stop_circle_outlined;
    return Icons.help_outline;
  }

  String get label {
    if (sub != null) return '$base:$sub';
    return base;
  }
}