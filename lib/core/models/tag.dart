import '../utils/json.dart';

class Tag {
  const Tag({this.id, this.name, this.color, this.createdAt, this.updatedAt});

  final int? id;
  final String? name;
  final String? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Tag.fromJson(Map<String, dynamic> m) => Tag(
        id: jsonInt(m, 'id'),
        name: jsonStr(m, 'name'),
        color: jsonStr(m, 'color'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
      );
}

/// Response of `GET /applications/{uuid}/tags` — a list of attached tags.
class ResourceTags {
  const ResourceTags({this.tags = const []});

  final List<Tag> tags;

  factory ResourceTags.fromJson(Map<String, dynamic> m) => ResourceTags(
        tags: jsonList(m, 'tags')
            .map(Tag.fromJson)
            .toList(),
      );
}

class AuditEvent {
  const AuditEvent({this.id, this.action, this.details, this.userName, this.createdAt});

  final int? id;
  final String? action;
  final Map<String, dynamic>? details;
  final String? userName;
  final DateTime? createdAt;

  factory AuditEvent.fromJson(Map<String, dynamic> m) => AuditEvent(
        id: jsonInt(m, 'id'),
        action: jsonStr(m, 'action'),
        details: jsonMap(m, 'details'),
        userName: jsonStr(m, 'user_name') ?? jsonStr(m, 'user'),
        createdAt: jsonDt(m, 'created_at'),
      );
}

class ScheduledTask {
  const ScheduledTask({
    this.id,
    this.uuid,
    this.name,
    this.command,
    this.frequency,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? uuid;
  final String? name;
  final String? command;
  final String? frequency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ScheduledTask.fromJson(Map<String, dynamic> m) => ScheduledTask(
        id: jsonInt(m, 'id'),
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        command: jsonStr(m, 'command'),
        frequency: jsonStr(m, 'frequency'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
      );
}

class TaskExecution {
  const TaskExecution({this.id, this.status, this.message, this.createdAt});

  final int? id;
  final String? status;
  final String? message;
  final DateTime? createdAt;

  factory TaskExecution.fromJson(Map<String, dynamic> m) => TaskExecution(
        id: jsonInt(m, 'id'),
        status: jsonStr(m, 'status'),
        message: jsonStr(m, 'message'),
        createdAt: jsonDt(m, 'created_at'),
      );
}

class Storage {
  const Storage({
    this.id,
    this.uuid,
    this.name,
    this.hostPath,
    this.mountPath,
    this.size,
    this.isReadOnly,
    this.isBackupOnly,
    this.type,
  });

  final int? id;
  final String? uuid;
  final String? name;
  final String? hostPath;
  final String? mountPath;
  final int? size;
  final bool? isReadOnly;
  final bool? isBackupOnly;
  final String? type;

  factory Storage.fromJson(Map<String, dynamic> m) => Storage(
        id: jsonInt(m, 'id'),
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        hostPath: jsonStr(m, 'host_path'),
        mountPath: jsonStr(m, 'mount_path'),
        size: jsonInt(m, 'size'),
        isReadOnly: jsonBool(m, 'is_read_only'),
        isBackupOnly: jsonBool(m, 'is_backup_only'),
        type: jsonStr(m, 'type'),
      );
}

class LogsResult {
  const LogsResult({this.logs = '', this.meta});

  final String logs;
  final Map<String, dynamic>? meta;

  factory LogsResult.fromJson(Map<String, dynamic> m) => LogsResult(
        logs: jsonStrOr(m, 'logs'),
        meta: jsonMap(m, 'meta'),
      );
}

class MessageResult {
  const MessageResult({this.message, this.deploymentUuid, this.raw = const {}});

  final String? message;
  final String? deploymentUuid;
  final Map<String, dynamic> raw;

  factory MessageResult.fromJson(Map<String, dynamic> m) => MessageResult(
        message: jsonStr(m, 'message'),
        deploymentUuid: jsonStr(m, 'deployment_uuid'),
        raw: m,
      );
}