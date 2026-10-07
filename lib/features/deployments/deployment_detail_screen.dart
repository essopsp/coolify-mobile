import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/deployment.dart';
import '../../core/providers.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/confirm.dart';
import 'widgets.dart';

class DeploymentDetailScreen extends ConsumerStatefulWidget {
  const DeploymentDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<DeploymentDetailScreen> createState() =>
      _DeploymentDetailScreenState();
}

class _DeploymentDetailScreenState extends ConsumerState<DeploymentDetailScreen> {
  Deployment? _deployment;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final d = await ref.read(apiProvider).deployment(widget.uuid);
      if (mounted) {
        setState(() {
          _deployment = d;
          _error = null;
        });
      }
      if (d.isActive) {
        _startPolling();
      } else {
        _timer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  void _startPolling() {
    _timer ??= Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  Future<void> _cancel() async {
    final ok = await confirmAction(
      context,
      title: 'Cancel deployment?',
      message: 'This stops the running build. Already-built steps are kept.',
      confirmLabel: 'Cancel deployment',
      destructive: true,
    );
    if (!ok) return;
    if (!mounted) return;
    await showBusy(
      context,
      action: () =>
          ref.read(apiProvider).cancelDeployment(widget.uuid),
      successMessage: 'Cancellation requested.',
      busyLabel: 'Cancelling…',
    );
    _timer?.cancel();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _deployment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deployment'),
        actions: [
          if (d != null && d.isActive)
            IconButton(
              onPressed: _cancel,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel',
            ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load deployment:\n$_error',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        setState(() {
                          _error = null;
                        });
                        await _load(initial: true);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : _buildDetail(context, d),
    );
  }

  Widget _buildDetail(BuildContext context, Deployment d) {
    final status = d.parsedStatus;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: status.color(context).withValues(alpha: 0.08),
            child: Row(
              children: [
                status.isActive
                    ? const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Icon(status.icon, size: 34, color: status.color(context)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deploymentProgressLabel(status),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        truncateMiddle(d.deploymentUuid ?? '', 24),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _InfoRow('Application', d.applicationName ?? d.applicationId?.toString()),
          if (d.serverName != null && d.serverName!.isNotEmpty)
            _InfoRow('Server', d.serverName),
          _InfoRow('Started', formatDateTime(d.createdAt)),
          _InfoRow('Updated', formatDateTime(d.updatedAt)),
          if (d.commit != null) _InfoRow('Commit', d.commit),
          if (d.commitMessage != null && d.commitMessage!.isNotEmpty)
            _InfoRow('Commit message', d.commitMessage),
          if (d.pullRequestId != null) _InfoRow('Pull request', '${d.pullRequestId}'),
          if (d.forceRebuild ?? false) const _InfoRow('Mode', 'Force rebuild'),
          if (d.restartOnly ?? false) const _InfoRow('Mode', 'Restart only'),
          if (d.deploymentUrl != null && d.deploymentUrl!.isNotEmpty)
            _InfoRow('URL', d.deploymentUrl),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Build output',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (d.logs != null && d.logs!.isNotEmpty)
            DeploymentLogView(logs: d.logs!)
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Logs are shown on the Coolify dashboard for API-triggered '
                'deployments. Polling this screen updates status in real time.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value ?? '—',
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}