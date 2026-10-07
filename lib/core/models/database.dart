import '../utils/json.dart';
import '../utils/status.dart';

class Database {
  const Database({
    this.uuid,
    this.name,
    this.status,
    this.type,
    this.image,
    this.description,
    this.fqdn,
    this.portsMappings,
    this.portsExposes,
    this.isPublic,
    this.isReady,
    this.createdAt,
    this.updatedAt,
    this.publicPort,
    this.databaseType,
  });

  final String? uuid;
  final String? name;
  final String? status;
  final String? type;
  final String? image;
  final String? description;
  final String? fqdn;
  final String? portsMappings;
  final String? portsExposes;
  final bool? isPublic;
  final bool? isReady;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? publicPort;
  final String? databaseType;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  String? get dbEngine =>
      type ?? databaseType ?? (image?.split('/').last.split(':').first);

  factory Database.fromJson(Map<String, dynamic> m) => Database(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        status: jsonStr(m, 'status'),
        type: jsonStr(m, 'type') ?? jsonStr(m, 'db_type') ?? jsonStr(m, 'image'),
        image: jsonStr(m, 'image'),
        description: jsonStr(m, 'description'),
        fqdn: jsonStr(m, 'fqdn'),
        portsMappings: jsonStr(m, 'ports_mappings'),
        portsExposes: jsonStr(m, 'ports_exposes'),
        isPublic: jsonBool(m, 'is_public'),
        isReady: jsonBool(m, 'is_ready'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
        publicPort: jsonInt(m, 'public_port'),
        databaseType: jsonStr(m, 'db_type'),
      );
}

class Backup {
  const Backup({
    this.uuid,
    this.name,
    this.frequency,
    this.enabled,
    this.databases,
    this.s3StorageId,
    this.lastExecutionAt,
    this.nextExecution,
    this.id,
  });

  final String? uuid;
  final String? name;
  final String? frequency;
  final bool? enabled;
  final String? databases;
  final int? s3StorageId;
  final DateTime? lastExecutionAt;
  final DateTime? nextExecution;
  final int? id;

  factory Backup.fromJson(Map<String, dynamic> m) => Backup(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        frequency: jsonStr(m, 'frequency'),
        enabled: jsonBool(m, 'enabled'),
        databases: jsonStr(m, 'databases'),
        s3StorageId: jsonInt(m, 's3_storage_id'),
        lastExecutionAt: jsonDt(m, 'last_execution_at'),
        nextExecution: jsonDt(m, 'next_execution'),
        id: jsonInt(m, 'id'),
      );
}

class BackupExecution {
  const BackupExecution({
    this.id,
    this.status,
    this.message,
    this.executionId,
    this.sizeInBytes,
    this.fileName,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? status;
  final String? message;
  final String? executionId;
  final int? sizeInBytes;
  final String? fileName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BackupExecution.fromJson(Map<String, dynamic> m) => BackupExecution(
        id: jsonInt(m, 'id'),
        status: jsonStr(m, 'status'),
        message: jsonStr(m, 'message'),
        executionId: jsonStr(m, 'execution_id'),
        sizeInBytes: jsonInt(m, 'size_in_bytes'),
        fileName: jsonStr(m, 'file_name'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
      );
}