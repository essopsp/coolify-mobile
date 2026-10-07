import 'package:flutter/material.dart' show IconData, Icons;

import '../utils/json.dart';
import '../utils/status.dart';
import 'environment.dart';

class Project {
  const Project({
    this.uuid,
    this.name,
    this.description,
    this.environments = const [],
    this.counts,
  });

  final String? uuid;
  final String? name;
  final String? description;
  final List<Environment> environments;
  final ProjectCounts? counts;

  factory Project.fromJson(Map<String, dynamic> m) {
    final countsJson = jsonMap(m, 'counts');
    return Project(
      uuid: jsonStr(m, 'uuid'),
      name: jsonStr(m, 'name'),
      description: jsonStr(m, 'description'),
      environments:
          jsonList(m, 'environments').map(Environment.fromJson).toList(),
      counts: countsJson == null ? null : ProjectCounts.fromJson(countsJson),
    );
  }
}

class ProjectCounts {
  const ProjectCounts({this.applications = 0, this.services = 0, this.databases = 0});

  final int applications;
  final int services;
  final int databases;

  int get total => applications + services + databases;

  factory ProjectCounts.fromJson(Map<String, dynamic> m) => ProjectCounts(
        applications: jsonIntOr(m, 'applications'),
        services: jsonIntOr(m, 'services'),
        databases: jsonIntOr(m, 'databases'),
      );
}

/// Resource type string as returned by `GET /resources`.
enum ResourceType { application, service, database, databaseProxy, unknown }

ResourceType resourceTypeFromJson(String? s) => switch (s) {
      'application' => ResourceType.application,
      'service' => ResourceType.service,
      'database' => ResourceType.database,
      'database-proxy' => ResourceType.databaseProxy,
      _ => ResourceType.unknown,
    };

String resourceTypeLabel(ResourceType t) => switch (t) {
      ResourceType.application => 'Application',
      ResourceType.service => 'Service',
      ResourceType.database => 'Database',
      ResourceType.databaseProxy => 'DB Proxy',
      ResourceType.unknown => 'Resource',
    };

IconData resourceTypeIcon(ResourceType t) => switch (t) {
      ResourceType.application => Icons.web_asset,
      ResourceType.service => Icons.layers,
      ResourceType.database => Icons.storage,
      ResourceType.databaseProxy => Icons.swap_vert,
      ResourceType.unknown => Icons.widgets_outlined,
    };

class Resource {
  const Resource({
    this.uuid,
    this.name,
    this.type = ResourceType.unknown,
    this.status,
    this.projectUuid,
    this.projectName,
    this.environmentName,
    this.environmentUuid,
    this.tags = const [],
  });

  final String? uuid;
  final String? name;
  final ResourceType type;
  final String? status;
  final String? projectUuid;
  final String? projectName;
  final String? environmentName;
  final String? environmentUuid;
  final List<String> tags;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  factory Resource.fromJson(Map<String, dynamic> m) => Resource(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name') ?? jsonStr(m, 'fqdn'),
        type: resourceTypeFromJson(jsonStr(m, 'type')),
        status: jsonStr(m, 'status'),
        projectUuid: jsonStr(m, 'project_uuid'),
        projectName: jsonStr(m, 'project_name'),
        environmentName: jsonStr(m, 'environment_name'),
        environmentUuid: jsonStr(m, 'environment_uuid') ?? jsonStr(m, 'environment_id'),
        tags: jsonStrList(m, 'tags'),
      );
}