import '../utils/json.dart';
import '../utils/status.dart';

class Deployment {
  const Deployment({
    this.id,
    this.deploymentUuid,
    this.applicationId,
    this.applicationName,
    this.serverId,
    this.serverName,
    this.status,
    this.commit,
    this.commitMessage,
    this.pullRequestId,
    this.forceRebuild,
    this.restartOnly,
    this.isApi,
    this.isWebhook,
    this.deploymentUrl,
    this.dockerRegistryImageTag,
    this.createdAt,
    this.updatedAt,
    this.logs,
    this.destinationId,
    this.gitType,
  });

  final int? id;
  final String? deploymentUuid;
  final int? applicationId;
  final String? applicationName;
  final int? serverId;
  final String? serverName;
  final String? status;
  final String? commit;
  final String? commitMessage;
  final int? pullRequestId;
  final bool? forceRebuild;
  final bool? restartOnly;
  final bool? isApi;
  final bool? isWebhook;
  final String? deploymentUrl;
  final String? dockerRegistryImageTag;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? logs;
  final String? destinationId;
  final String? gitType;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  bool get isActive => status == 'queued' || status == 'in_progress' || status == 'building';

  factory Deployment.fromJson(Map<String, dynamic> m) => Deployment(
        id: jsonInt(m, 'id'),
        deploymentUuid:
            jsonStr(m, 'deployment_uuid') ?? jsonStr(m, 'uuid'),
        applicationId: jsonInt(m, 'application_id'),
        applicationName: jsonStr(m, 'application_name'),
        serverId: jsonInt(m, 'server_id'),
        serverName: jsonStr(m, 'server_name'),
        status: jsonStr(m, 'status'),
        commit: jsonStr(m, 'commit'),
        commitMessage: jsonStr(m, 'commit_message'),
        pullRequestId: jsonInt(m, 'pull_request_id'),
        forceRebuild: jsonBool(m, 'force_rebuild'),
        restartOnly: jsonBool(m, 'restart_only'),
        isApi: jsonBool(m, 'is_api'),
        isWebhook: jsonBool(m, 'is_webhook'),
        deploymentUrl: jsonStr(m, 'deployment_url'),
        dockerRegistryImageTag: jsonStr(m, 'docker_registry_image_tag'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
        logs: jsonStr(m, 'logs'),
        destinationId: jsonStr(m, 'destination_id'),
        gitType: jsonStr(m, 'git_type'),
      );
}

class DeployResult {
  const DeployResult({this.deploymentUuid, this.message});

  final String? deploymentUuid;
  final String? message;

  factory DeployResult.fromJson(Map<String, dynamic> m) => DeployResult(
        deploymentUuid: jsonStr(m, 'deployment_uuid'),
        message: jsonStr(m, 'message'),
      );
}