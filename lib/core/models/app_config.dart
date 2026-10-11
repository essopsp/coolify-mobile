import '../utils/json.dart';

/// Editable configuration shared by the create sheets and the settings
/// screens. Covers the Coolify v1 application PATCH surface we expose.
class AppConfig {
  const AppConfig({
    this.name,
    this.description,
    this.domains,
    this.buildPack,
    this.baseDirectory,
    this.publishDirectory,
    this.installCommand,
    this.startCommand,
    this.buildCommand,
    this.portsExposes,
    this.portsMappings,
    this.healthCheckEnabled,
    this.healthCheckPath,
    this.healthCheckPort,
    this.healthCheckHost,
    this.healthCheckMethod,
    this.healthCheckInterval,
    this.healthCheckTimeout,
    this.healthCheckRetries,
    this.healthCheckStartPeriod,
    this.dockerfile,
    this.dockerComposeLocation,
    this.dockerComposeRaw,
    this.dockerComposeDomains,
    this.customDockerRunOptions,
    this.isStatic,
    this.limitsMemory,
    this.limitsCpus,
    this.limitsCpuShares,
  });

  final String? name;
  final String? description;

  /// Newline-separated domains. Coolify stores one domain per line.
  final String? domains;

  final String? buildPack;
  final String? baseDirectory;
  final String? publishDirectory;
  final String? installCommand;
  final String? startCommand;
  final String? buildCommand;

  final String? portsExposes;
  final String? portsMappings;

  final bool? healthCheckEnabled;
  final String? healthCheckPath;
  final String? healthCheckPort;
  final String? healthCheckHost;
  final String? healthCheckMethod;
  final String? healthCheckInterval;
  final String? healthCheckTimeout;
  final String? healthCheckRetries;
  final String? healthCheckStartPeriod;

  /// Path to the Dockerfile inside the repository.
  final String? dockerfile;
  final String? dockerComposeLocation;

  /// Raw docker-compose.yml content (one-click services edit this).
  final String? dockerComposeRaw;

  /// Newline-separated domains for the compose stack.
  final String? dockerComposeDomains;
  final String? customDockerRunOptions;

  final bool? isStatic;
  final String? limitsMemory;
  final String? limitsCpus;
  final String? limitsCpuShares;

  factory AppConfig.fromApplicationJson(Map<String, dynamic> m) {
    final domains = jsonStr(m, 'domains') ?? jsonStr(m, 'fqdn');
    return AppConfig(
      name: jsonStr(m, 'name'),
      description: jsonStr(m, 'description'),
      domains: domains,
      buildPack: jsonStr(m, 'build_pack'),
      baseDirectory: jsonStr(m, 'base_directory'),
      publishDirectory: jsonStr(m, 'publish_directory'),
      installCommand: jsonStr(m, 'install_command'),
      startCommand: jsonStr(m, 'start_command'),
      buildCommand: jsonStr(m, 'build_command'),
      portsExposes: jsonStr(m, 'ports_exposes'),
      portsMappings: jsonStr(m, 'ports_mappings'),
      healthCheckEnabled: jsonBool(m, 'health_check_enabled'),
      healthCheckPath: jsonStr(m, 'health_check_path'),
      healthCheckPort: jsonStr(m, 'health_check_port'),
      healthCheckHost: jsonStr(m, 'health_check_host'),
      healthCheckMethod: jsonStr(m, 'health_check_method'),
      healthCheckInterval: jsonStr(m, 'health_check_interval'),
      healthCheckTimeout: jsonStr(m, 'health_check_timeout'),
      healthCheckRetries: jsonStr(m, 'health_check_retries'),
      healthCheckStartPeriod: jsonStr(m, 'health_check_start_period'),
      dockerfile: jsonStr(m, 'dockerfile') ?? jsonStr(m, 'dockerfile_location'),
      dockerComposeLocation: jsonStr(m, 'docker_compose_location'),
      dockerComposeRaw: jsonStr(m, 'docker_compose_raw'),
      dockerComposeDomains: _joinList(m, 'docker_compose_domains'),
      customDockerRunOptions: jsonStr(m, 'custom_docker_run_options'),
      isStatic: jsonBool(m, 'is_static'),
      limitsMemory: jsonStr(m, 'limits_memory'),
      limitsCpus: jsonStr(m, 'limits_cpus'),
      limitsCpuShares: jsonStr(m, 'limits_cpu_shares'),
    );
  }

  /// Splits a `domains` textarea value into trimmed, non-empty entries.
  static List<String> splitDomains(String raw) => raw
      .split(RegExp(r'[\n,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// Request body for `PATCH /applications/{uuid}`.
  Map<String, dynamic> toPatchBody() {
    final body = <String, dynamic>{};
    void put(String key, Object? v) {
      if (v != null) body[key] = v;
    }

    put('name', _blankToNull(name));
    put('description', _blankToNull(description));
    put('domains', _blankToNull(domains));
    put('build_pack', buildPack);
    put('base_directory', baseDirectory);
    put('publish_directory', publishDirectory);
    put('install_command', _blankToNull(installCommand));
    put('start_command', _blankToNull(startCommand));
    put('build_command', _blankToNull(buildCommand));
    put('ports_exposes', _blankToNull(portsExposes));
    put('ports_mappings', _blankToNull(portsMappings));
    put('health_check_enabled', healthCheckEnabled);
    put('health_check_path', _blankToNull(healthCheckPath));
    put('health_check_port', _blankToNull(healthCheckPort));
    put('health_check_host', _blankToNull(healthCheckHost));
    put('health_check_method', healthCheckMethod);
    put('health_check_interval', healthCheckInterval);
    put('health_check_timeout', healthCheckTimeout);
    put('health_check_retries', healthCheckRetries);
    put('health_check_start_period', healthCheckStartPeriod);
    put('dockerfile', _blankToNull(dockerfile));
    put('docker_compose_location', _blankToNull(dockerComposeLocation));
    put('docker_compose_raw', _blankToNull(dockerComposeRaw));
    final composeDomains = splitDomains(dockerComposeDomains ?? '');
    if (composeDomains.isNotEmpty) body['docker_compose_domains'] = composeDomains;
    put('custom_docker_run_options', _blankToNull(customDockerRunOptions));
    put('is_static', isStatic);
    put('limits_memory', _blankToNull(limitsMemory));
    put('limits_cpus', _blankToNull(limitsCpus));
    put('limits_cpu_shares', limitsCpuShares);
    return body;
  }

  /// Request body for the create endpoints. Mirrors [toPatchBody] but keeps
  /// the null-omission behaviour so unspecified fields use Coolify defaults.
  Map<String, dynamic> toCreateBody() => toPatchBody();

  static String? _blankToNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static String? _joinList(Map<String, dynamic> m, String key) {
    final list = jsonStrList(m, key);
    if (list.isEmpty) return null;
    return list.join('\n');
  }
}

/// Editable configuration for a service (one-click or compose stack).
class ServiceConfig {
  const ServiceConfig({
    this.name,
    this.description,
    this.dockerComposeRaw,
    this.connectToDockerNetwork,
  });

  final String? name;
  final String? description;
  final String? dockerComposeRaw;
  final bool? connectToDockerNetwork;

  static const empty = ServiceConfig();

  factory ServiceConfig.fromJson(Map<String, dynamic> m) => ServiceConfig(
        name: jsonStr(m, 'name'),
        description: jsonStr(m, 'description'),
        dockerComposeRaw:
            jsonStr(m, 'docker_compose') ?? jsonStr(m, 'docker_compose_raw'),
        connectToDockerNetwork: jsonBool(m, 'connect_to_docker_network'),
      );

  Map<String, dynamic> toPatchBody() {
    final body = <String, dynamic>{};
    if (name != null && name!.trim().isNotEmpty) body['name'] = name!.trim();
    if (description != null) body['description'] = description;
    if (dockerComposeRaw != null) body['docker_compose_raw'] = dockerComposeRaw;
    if (connectToDockerNetwork != null) {
      body['connect_to_docker_network'] = connectToDockerNetwork;
    }
    return body;
  }
}

/// Build packs the Coolify API accepts for an application.
const kBuildPacks = <String>[
  'nixpacks',
  'railpack',
  'static',
  'dockerfile',
  'dockercompose',
];

const kHealthCheckMethods = <String>['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'];