import '../models/application.dart';
import '../models/coolify_instance.dart';
import '../models/database.dart';
import '../models/deployment.dart';
import '../models/environment.dart';
import '../models/resource.dart';
import '../models/server.dart';
import '../models/service.dart';
import '../models/tag.dart';
import '../models/team.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Typed facade over the Coolify REST API (v1).
class CoolifyApi {
  CoolifyApi(this._client);

  final ApiClient _client;

  static String stripJsonScheme(String s) =>
      s.replaceFirst('json://', '').replaceFirst('json+ssh://', '');

  /// The public API uses plural resource segments.
  static String _resourcePlural(String resource) => switch (resource) {
        'application' => 'applications',
        'database' || 'databaseProxy' => 'databases',
        'service' => 'services',
        'server' => 'servers',
        _ => resource,
      };

  // ── System / health ────────────────────────────────────────────────────────
  Future<String> version() async {
    final data = await _client.get('/version');
    if (data is Map<String, dynamic>) {
      return (data['version'] ?? data['messages'] ?? data.toString()).toString();
    }
    return data?.toString() ?? 'unknown';
  }

  Future<Team> team() async {
    final data = await _client.get('/team');
    return Team.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<TeamMember>> teamMembers() async {
    final data = await _client.get('/team/members');
    if (data is! List) return const [];
    return data
        .map((e) => TeamMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AuditEvent>> auditEvents() async {
    try {
      final data = await _client.get('/audit-events');
      if (data is! List) return const [];
      return data
          .map((e) => AuditEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.notFound) {
        throw const ApiException(
          ApiErrorKind.notFound,
          'This Coolify version does not expose audit events via the public API (v1).',
        );
      }
      rethrow;
    }
  }

  // ── Projects ───────────────────────────────────────────────────────────────
  Future<List<Project>> projects() async {
    final data = await _client.get('/projects');
    if (data is! List) return const [];
    return data
        .map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Project> project(String uuid) async {
    final data = await _client.get('/projects/$uuid');
    return Project.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MessageResult> createProject(String name, String? description) async {
    final data = await _client.post('/projects',
        body: {'name': name, 'description': ?description});
    return _msg(data);
  }

  Future<MessageResult> renameProject(String uuid, String name) async {
    final data = await _client.patch('/projects/$uuid', body: {'name': name});
    return _msg(data);
  }

  Future<MessageResult> deleteProject(String uuid) async {
    final data = await _client.delete('/projects/$uuid');
    return _msg(data);
  }

  // ── Resources / overview ───────────────────────────────────────────────────
  Future<List<Resource>> resources({String? projectUuid, String? environmentUuid}) async {
    final data = await _client.get('/resources', query: {
      'project_uuid': ?projectUuid,
      'environment_uuid': ?environmentUuid,
    });
    if (data is! List) return const [];
    return data
        .map((e) => Resource.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Application>> applications() async {
    final data = await _client.get('/applications');
    if (data is! List) return const [];
    return data
        .map((e) => Application.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Application> application(String uuid) async {
    final data = await _client.get('/applications/$uuid');
    return Application.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Database>> databases() async {
    final data = await _client.get('/databases');
    if (data is! List) return const [];
    return data
        .map((e) => Database.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Database> database(String uuid) async {
    final data = await _client.get('/databases/$uuid');
    return Database.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Service>> services() async {
    final data = await _client.get('/services');
    if (data is! List) return const [];
    return data
        .map((e) => Service.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Service> service(String uuid) async {
    final data = await _client.get('/services/$uuid');
    return Service.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ServiceApp>> serviceApplications(String serviceUuid) async {
    final data = await _client.get('/services/$serviceUuid/applications');
    if (data is! List) return const [];
    return data
        .map((e) => ServiceApp.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ServiceDatabase>> serviceDatabases(String serviceUuid) async {
    final data = await _client.get('/services/$serviceUuid/databases');
    if (data is! List) return const [];
    return data
        .map((e) => ServiceDatabase.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Lifecycle actions ──────────────────────────────────────────────────────
  /// resource: application | database | service
  /// action: start | stop | restart
  Future<MessageResult> control(
    String resource,
    String uuid,
    String action, {
    bool force = false,
    bool confirmStopped = false,
  }) async {
    final path = '/${_resourcePlural(resource)}/$uuid/$action';
    final data = action == 'stop'
        ? await _client.post(path, query: {'confirm': true}, body: {})
        : await _client.post(path, query: {'force': force}, body: {});
    return _msg(data);
  }

  Future<List<DeployResult>> deploy(
    String uuid, {
    bool force = false,
    int? pullRequestId,
  }) async {
    final data = await _client.post('/deploy', query: {
      'uuid': uuid,
      if (force) 'force': true,
      'pull_request_id': ?pullRequestId,
    });
    if (data is! List) return const [];
    return data
        .map((e) => DeployResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MessageResult> rollback(String uuid, String version) async {
    final data =
        await _client.post('/applications/$uuid/rollback', body: {'version': version});
    return _msg(data);
  }

  Future<List<String>> rollbackImages(String uuid) async {
    final data = await _client.get('/applications/$uuid/rollback-images');
    if (data is! List) return const [];
    return data.whereType<String>().toList();
  }

  Future<MessageResult> restart(
    String resource,
    String uuid, {
    bool force = false,
    int? rollback,
  }) async {
    final data = resource == 'service'
        ? await _client.post('/services/$uuid/restart',
            query: {'force': force}, body: {})
        : await _client.post('/${_resourcePlural(resource)}/$uuid/restart',
            query: {'force': force}, body: {});
    return _msg(data);
  }

  Future<MessageResult> serviceAppControl(
    String serviceUuid,
    String appUuid,
    String action,
  ) async {
    final data = await _client.post(
      '/services/$serviceUuid/applications/$appUuid/$action',
      body: {},
    );
    return _msg(data);
  }

  Future<MessageResult> serviceDbControl(
    String serviceUuid,
    String dbUuid,
    String action,
  ) async {
    final data = await _client.post(
      '/services/$serviceUuid/databases/$dbUuid/$action',
      body: {},
    );
    return _msg(data);
  }

  // ── Deployments ────────────────────────────────────────────────────────────
  Future<List<Deployment>> runningDeployments() async {
    final data = await _client.get('/deployments');
    if (data is! List) return const [];
    return data
        .map((e) => Deployment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Deployment>> appDeployments(String appUuid) async {
    final data = await _client.get('/deployments/applications/$appUuid');
    if (data is! List) return const [];
    return data
        .map((e) => Deployment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Deployment> deployment(String uuid) async {
    final data = await _client.get('/deployments/$uuid');
    return Deployment.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MessageResult> cancelDeployment(String uuid) async {
    final data = await _client.post('/deployments/$uuid/cancel');
    return _msg(data);
  }

  // ── Env vars ───────────────────────────────────────────────────────────────
  Future<List<EnvVar>> envVars(String resource, String uuid) async {
    final data = await _client.get('/${_resourcePlural(resource)}/$uuid/envs');
    if (data is! List) return const [];
    return data
        .map((e) => EnvVar.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MessageResult> addEnvVars(
    String resource,
    String uuid, {
    required String key,
    String? value,
    bool buildTime = false,
    bool preview = false,
  }) async {
    final data = await _client.post('/${_resourcePlural(resource)}/$uuid/envs', body: {
      'key': key,
      'value': ?value,
      'is_build_time': buildTime,
      'is_preview': preview,
    });
    return _msg(data);
  }

  Future<MessageResult> patchEnvVarsBulk(
    String resource,
    String uuid, {
    required String key,
    String? value,
    bool buildTime = false,
    bool preview = false,
  }) async {
    final data = await _client.patch('/${_resourcePlural(resource)}/$uuid/envs/bulk', body: [
      {
        'key': key,
        'value': ?value,
        'is_build_time': buildTime,
        'is_preview': preview,
      }
    ]);
    return _msg(data);
  }

  Future<MessageResult> deleteEnvVar(String resource, String uuid, String envUuid) async {
    final data = await _client.delete('/${_resourcePlural(resource)}/$uuid/envs/$envUuid');
    return _msg(data);
  }

  // ── Logs ───────────────────────────────────────────────────────────────────
  Future<String> logs(
    String resource,
    String uuid, {
    int lines = 200,
    bool timestamps = false,
    String? serviceName,
  }) async {
    final data = await _client.get('/${_resourcePlural(resource)}/$uuid/logs', query: {
      'lines': lines,
      'show_timestamps': timestamps,
      if (serviceName != null && serviceName.isNotEmpty) 'service_name': serviceName,
    });
    if (data is Map<String, dynamic>) {
      return (data['logs'] ?? '').toString();
    }
    return data?.toString() ?? '';
  }

  Future<String> serviceAppLogs(
    String serviceUuid,
    String appUuid, {
    int lines = 200,
    bool timestamps = false,
  }) async {
    return _logsFrom(
      '/services/$serviceUuid/applications/$appUuid/logs',
      lines: lines,
      timestamps: timestamps,
    );
  }

  Future<String> serviceDbLogs(
    String serviceUuid,
    String dbUuid, {
    int lines = 200,
    bool timestamps = false,
  }) async {
    return _logsFrom(
      '/services/$serviceUuid/databases/$dbUuid/logs',
      lines: lines,
      timestamps: timestamps,
    );
  }

  Future<String> _logsFrom(
    String path, {
    int lines = 200,
    bool timestamps = false,
    String? serviceName,
  }) async {
    final data = await _client.get(path, query: {
      'lines': lines,
      'show_timestamps': timestamps,
      if (serviceName != null && serviceName.isNotEmpty) 'service_name': serviceName,
    });
    if (data is Map<String, dynamic>) return (data['logs'] ?? '').toString();
    return data?.toString() ?? '';
  }

  // ── Tags ───────────────────────────────────────────────────────────────────
  Future<List<Tag>> tags() async {
    final data = await _client.get('/tags');
    if (data is! List) return const [];
    return data.map((e) => Tag.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<MessageResult> createTag(String name, String? color) async {
    final data = await _client.post('/tags',
        body: {'name': name, 'color': ?color});
    return _msg(data);
  }

  Future<MessageResult> updateTag(String uuid, String name, String? color) async {
    final data = await _client.patch('/tags/$uuid',
        body: {'name': name, 'color': ?color});
    return _msg(data);
  }

  Future<MessageResult> deleteTag(String uuid) async {
    final data = await _client.delete('/tags/$uuid');
    return _msg(data);
  }

  Future<List<Tag>> resourceTags(String resource, String uuid) async {
    final data = await _client.get('/${_resourcePlural(resource)}/$uuid/tags');
    if (data is Map<String, dynamic>) {
      return data['tags'] is List
          ? (data['tags'] as List)
              .map((e) => Tag.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [];
    }
    if (data is List) {
      return data
          .map((e) => Tag.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  Future<MessageResult> addTagToResource(
    String resource,
    String uuid,
    String tagUuid,
  ) async {
    final data = await _client.post('/${_resourcePlural(resource)}/$uuid/tags',
        body: {'tag_uuid': tagUuid});
    return _msg(data);
  }

  Future<MessageResult> removeTagFromResource(
    String resource,
    String uuid,
    String tagUuid,
  ) async {
    final data = await _client.delete('/${_resourcePlural(resource)}/$uuid/tags/$tagUuid');
    return _msg(data);
  }

  // ── Scheduled tasks ────────────────────────────────────────────────────────
  Future<List<ScheduledTask>> tasks(String resource, String uuid) async {
    final data = await _client.get('/${_resourcePlural(resource)}/$uuid/scheduled-tasks');
    if (data is! List) return const [];
    return data
        .map((e) => ScheduledTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MessageResult> createTask(
    String resource,
    String uuid, {
    required String name,
    required String command,
    required String frequency,
  }) async {
    final data = await _client.post('/${_resourcePlural(resource)}/$uuid/scheduled-tasks', body: {
      'name': name,
      'command': command,
      'frequency': frequency,
    });
    return _msg(data);
  }

  Future<MessageResult> deleteTask(String resource, String uuid, String taskUuid) async {
    final data = await _client.delete('/${_resourcePlural(resource)}/$uuid/scheduled-tasks/$taskUuid');
    return _msg(data);
  }

  Future<MessageResult> executeTask(String resource, String uuid, String taskUuid) async {
    final data = await _client.post('/${_resourcePlural(resource)}/$uuid/scheduled-tasks/$taskUuid/execute');
    return _msg(data);
  }

  Future<List<TaskExecution>> taskExecutions(
    String resource,
    String uuid,
    String taskUuid,
  ) async {
    final data = await _client.get('/${_resourcePlural(resource)}/$uuid/scheduled-tasks/$taskUuid/executions');
    if (data is! List) return const [];
    return data
        .map((e) => TaskExecution.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Storages ───────────────────────────────────────────────────────────────
  Future<List<Storage>> storages(String resource, String uuid) async {
    final data = await _client.get('/${_resourcePlural(resource)}/$uuid/storages');
    if (data is! List) return const [];
    return data
        .map((e) => Storage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Server sub-resources ───────────────────────────────────────────────────
  Future<List<ServerResource>> serverResources(String uuid) async {
    final data = await _client.get('/servers/$uuid/resources');
    if (data is! List) return const [];
    return data
        .map((e) => ServerResource.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Server>> servers() async {
    final data = await _client.get('/servers');
    if (data is! List) return const [];
    return data
        .map((e) => Server.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Server> server(String uuid) async {
    final data = await _client.get('/servers/$uuid');
    if (data is! Map) throw Exception('Invalid server response');
    return Server.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ServerDomain>> serverDomains(String uuid) async {
    final data = await _client.get('/servers/$uuid/domains');
    if (data is! List) return const [];
    return data
        .map((e) => ServerDomain.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MessageResult> validateServer(String uuid) async {
    final data = await _client.post('/servers/$uuid/validate');
    return _msg(data);
  }

  Future<MessageResult> restartServerProxy(String uuid) async {
    final data = await _client.post('/servers/$uuid/proxy/restart');
    return _msg(data);
  }

  Future<Map<String, dynamic>> dockerCleanup(String uuid) async {
    final data = await _client.get('/servers/$uuid/docker-cleanup');
    return data is Map<String, dynamic> ? data : const {};
  }

  Future<MessageResult> runDockerCleanup(String uuid) async {
    final data = await _client.post('/servers/$uuid/docker-cleanup/run');
    return _msg(data);
  }

  // ── Databases backups ──────────────────────────────────────────────────────
  Future<List<Backup>> databaseBackups(String dbUuid) async {
    final data = await _client.get('/databases/$dbUuid/backups');
    if (data is! List) return const [];
    return data
        .map((e) => Backup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MessageResult> createBackup(String dbUuid, {String? frequency, String? name}) async {
    final data = await _client.post('/databases/$dbUuid/backups', body: {
      'frequency': frequency ?? '0 0 * * *',
      'name': ?name,
    });
    return _msg(data);
  }

  Future<MessageResult> deleteBackup(String dbUuid, String backupUuid) async {
    final data = await _client.delete('/databases/$dbUuid/backups/$backupUuid');
    return _msg(data);
  }

  Future<MessageResult> runBackup(
    String dbUuid,
    String scheduledBackupUuid,
  ) async {
    final data = await _client.post(
      '/databases/$dbUuid/backups/$scheduledBackupUuid/executions',
    );
    return _msg(data);
  }

  Future<List<BackupExecution>> backupExecutions(
    String dbUuid,
    String scheduledBackupUuid,
  ) async {
    final data = await _client.get(
      '/databases/$dbUuid/backups/$scheduledBackupUuid/executions',
    );
    if (data is! List) return const [];
    return data
        .map((e) => BackupExecution.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Validates a connection: returns team name + version, throws on failure.
  Future<(String, String)> validateConnection(CoolifyInstance instance) async {
    final api = forInstance(instance);
    final versionData = await api._client.get('/version');
    final version =
        versionData is Map<String, dynamic>
            ? (versionData['version'] ?? 'unknown').toString()
            : versionData?.toString() ?? 'unknown';
    final teamData = await api._client.get('/team');
    final name =
        teamData is Map<String, dynamic>
            ? (teamData['name'] ?? 'Your team').toString()
            : 'Your team';
    return (name, version);
  }

  static CoolifyApi forInstance(CoolifyInstance instance) =>
      CoolifyApi(ApiClient(instance));

  // ── misc ───────────────────────────────────────────────────────────────────
  MessageResult _msg(dynamic data) {
    if (data is Map<String, dynamic>) return MessageResult.fromJson(data);
    return MessageResult(message: data?.toString(), raw: const {});
  }
}