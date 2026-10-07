import '../utils/json.dart';
import '../utils/status.dart';

class Service {
  const Service({
    this.uuid,
    this.name,
    this.status,
    this.description,
    this.dockerCompose,
    this.projectUuid,
    this.projectName,
    this.environmentName,
    this.environmentUuid,
    this.createdAt,
    this.updatedAt,
    this.fqdn,
  });

  final String? uuid;
  final String? name;
  final String? status;
  final String? description;
  final String? dockerCompose;
  final String? projectUuid;
  final String? projectName;
  final String? environmentName;
  final String? environmentUuid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fqdn;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  factory Service.fromJson(Map<String, dynamic> m) => Service(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        status: jsonStr(m, 'status'),
        description: jsonStr(m, 'description'),
        dockerCompose: jsonStr(m, 'docker_compose'),
        projectUuid: jsonStr(m, 'project_uuid'),
        projectName: jsonStr(m, 'project_name'),
        environmentName: jsonStr(m, 'environment_name'),
        environmentUuid: jsonStr(m, 'environment_uuid') ?? jsonStr(m, 'environment_id'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
        fqdn: jsonStr(m, 'fqdn'),
      );
}

class ServiceApp {
  const ServiceApp({
    this.id,
    this.uuid,
    this.name,
    this.status,
    this.fqdn,
    this.image,
    this.description,
    this.portsExposes,
    this.isPublic,
  });

  final int? id;
  final String? uuid;
  final String? name;
  final String? status;
  final String? fqdn;
  final String? image;
  final String? description;
  final String? portsExposes;
  final bool? isPublic;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  factory ServiceApp.fromJson(Map<String, dynamic> m) => ServiceApp(
        id: jsonInt(m, 'id'),
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        status: jsonStr(m, 'status'),
        fqdn: jsonStr(m, 'fqdn'),
        image: jsonStr(m, 'image'),
        description: jsonStr(m, 'description'),
        portsExposes: jsonStr(m, 'ports_exposes'),
        isPublic: jsonBool(m, 'is_public'),
      );
}

class ServiceDatabase {
  const ServiceDatabase({
    this.id,
    this.uuid,
    this.name,
    this.status,
    this.image,
    this.description,
    this.port,
    this.type,
  });

  final int? id;
  final String? uuid;
  final String? name;
  final String? status;
  final String? image;
  final String? description;
  final int? port;
  final String? type;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  factory ServiceDatabase.fromJson(Map<String, dynamic> m) => ServiceDatabase(
        id: jsonInt(m, 'id'),
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        status: jsonStr(m, 'status'),
        image: jsonStr(m, 'image'),
        description: jsonStr(m, 'description'),
        port: jsonInt(m, 'port'),
        type: jsonStr(m, 'type'),
      );
}