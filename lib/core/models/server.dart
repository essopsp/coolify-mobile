import '../utils/json.dart';
import '../utils/status.dart';

class Server {
  const Server({
    this.uuid,
    this.name,
    this.description,
    this.ip,
    this.port,
    this.user,
    this.proxy,
    this.settings,
    this.isReachable,
    this.isUsable,
    this.createdAt,
    this.updatedAt,
    this.connectionTimeout,
    this.swarmCluster,
    this.deletedAt,
    this.isValidating,
    this.dockerVersion,
  });

  final String? uuid;
  final String? name;
  final String? description;
  final String? ip;
  final int? port;
  final String? user;
  final ServerProxy? proxy;
  final ServerSettings? settings;
  final bool? isReachable;
  final bool? isUsable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? connectionTimeout;
  final bool? swarmCluster;
  final DateTime? deletedAt;
  final bool? isValidating;
  final String? dockerVersion;

  String get hostLabel => '$user@$ip${port != null ? ':$port' : ''}';

  factory Server.fromJson(Map<String, dynamic> m) {
    final proxyJson = jsonMap(m, 'proxy');
    final settingsJson = jsonMap(m, 'settings');
    return Server(
      uuid: jsonStr(m, 'uuid'),
      name: jsonStr(m, 'name'),
      description: jsonStr(m, 'description'),
      ip: jsonStr(m, 'ip'),
      port: jsonInt(m, 'port'),
      user: jsonStr(m, 'user'),
      proxy: proxyJson == null ? null : ServerProxy.fromJson(proxyJson),
      settings: settingsJson == null ? null : ServerSettings.fromJson(settingsJson),
      isReachable: jsonBool(m, 'is_reachable'),
      isUsable: jsonBool(m, 'is_usable'),
      createdAt: jsonDt(m, 'created_at'),
      updatedAt: jsonDt(m, 'updated_at'),
      connectionTimeout: jsonInt(m, 'connection_timeout'),
      swarmCluster: jsonBool(m, 'swarm_cluster'),
      deletedAt: jsonDt(m, 'deleted_at'),
      isValidating: jsonBool(m, 'is_validating'),
      dockerVersion: settingsJson?['docker_version'],
    );
  }
}

class ServerProxy {
  const ServerProxy({this.type, this.status, this.redirectEnabled});

  final String? type;
  final String? status;
  final bool? redirectEnabled;

  factory ServerProxy.fromJson(Map<String, dynamic> m) => ServerProxy(
        type: jsonStr(m, 'type'),
        status: jsonStr(m, 'status'),
        redirectEnabled: jsonBool(m, 'redirect_enabled'),
      );
}

class ServerSettings {
  const ServerSettings({
    this.isReachable,
    this.isUsable,
    this.isSwarmManager,
    this.isBuildServer,
    this.isCloudflareTunnel,
    this.wildcardDomain,
    this.concurrentBuilds,
    this.dockerVersion,
    this.serverTimezone,
    this.isTerminalEnabled,
  });

  final bool? isReachable;
  final bool? isUsable;
  final bool? isSwarmManager;
  final bool? isBuildServer;
  final bool? isCloudflareTunnel;
  final String? wildcardDomain;
  final int? concurrentBuilds;
  final String? dockerVersion;
  final String? serverTimezone;
  final bool? isTerminalEnabled;

  factory ServerSettings.fromJson(Map<String, dynamic> m) => ServerSettings(
        isReachable: jsonBool(m, 'is_reachable'),
        isUsable: jsonBool(m, 'is_usable'),
        isSwarmManager: jsonBool(m, 'is_swarm_manager'),
        isBuildServer: jsonBool(m, 'is_build_server'),
        isCloudflareTunnel: jsonBool(m, 'is_cloudflare_tunnel'),
        wildcardDomain: jsonStr(m, 'wildcard_domain'),
        concurrentBuilds: jsonInt(m, 'concurrent_builds'),
        dockerVersion: jsonStr(m, 'docker_version'),
        serverTimezone: jsonStr(m, 'server_timezone'),
        isTerminalEnabled: jsonBool(m, 'is_terminal_enabled'),
      );
}

class ServerResource {
  const ServerResource({this.uuid, this.name, this.type, this.status});

  final String? uuid;
  final String? name;
  final String? type;
  final String? status;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  factory ServerResource.fromJson(Map<String, dynamic> m) => ServerResource(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        type: jsonStr(m, 'type'),
        status: jsonStr(m, 'status'),
      );
}

class ServerDomain {
  const ServerDomain({this.domain, this.type, this.caddyRemote, this.isTraefik});

  final String? domain;
  final String? type;
  final bool? caddyRemote;
  final bool? isTraefik;

  factory ServerDomain.fromJson(Map<String, dynamic> m) => ServerDomain(
        domain: jsonStr(m, 'domain'),
        type: jsonStr(m, 'type'),
        caddyRemote: jsonBool(m, 'caddy_remote'),
        isTraefik: jsonBool(m, 'is_traefik'),
      );
}

class DockerCleanupStatus {
  const DockerCleanupStatus({this.containers, this.images, this.networks, this.volumes});

  final int? containers;
  final int? images;
  final int? networks;
  final int? volumes;

  factory DockerCleanupStatus.fromJson(Map<String, dynamic> m) => DockerCleanupStatus(
        containers: jsonInt(m, 'containers'),
        images: jsonInt(m, 'images'),
        networks: jsonInt(m, 'networks'),
        volumes: jsonInt(m, 'volumes'),
      );
}