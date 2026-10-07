import '../utils/json.dart';
import '../utils/status.dart';

class Application {
  const Application({
    this.uuid,
    this.name,
    this.fqdn,
    this.status,
    this.gitRepository,
    this.gitBranch,
    this.gitCommitSha,
    this.buildPack,
    this.dockerRegistryImageName,
    this.dockerRegistryImageTag,
    this.staticImage,
    this.portsExposes,
    this.portsMappings,
    this.baseDirectory,
    this.publishDirectory,
    this.description,
    this.healthCheckEnabled,
    this.healthCheckPath,
    this.redirect,
    this.isHttpBasicAuthEnabled,
    this.dockerComposeLocation,
    this.dockerComposeDomains,
    this.previewUrlTemplate,
    this.createdAt,
    this.updatedAt,
    this.lastOnlineAt,
    this.containerPresent,
    this.noindexDomains,
    this.serverStatus,
    this.customDockerRunOptions,
    this.autoDeployEnabled,
    this.isStatic,
    this.isSpa,
  });

  final String? uuid;
  final String? name;
  final String? fqdn;
  final String? status;
  final String? gitRepository;
  final String? gitBranch;
  final String? gitCommitSha;
  final String? buildPack;
  final String? dockerRegistryImageName;
  final String? dockerRegistryImageTag;
  final String? staticImage;
  final String? portsExposes;
  final String? portsMappings;
  final String? baseDirectory;
  final String? publishDirectory;
  final String? description;
  final bool? healthCheckEnabled;
  final String? healthCheckPath;
  final String? redirect;
  final bool? isHttpBasicAuthEnabled;
  final String? dockerComposeLocation;
  final String? dockerComposeDomains;
  final String? previewUrlTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastOnlineAt;
  final bool? containerPresent;
  final String? noindexDomains;
  final bool? serverStatus;
  final String? customDockerRunOptions;
  final bool? autoDeployEnabled;
  final bool? isStatic;
  final bool? isSpa;

  ResourceStatus get parsedStatus => ResourceStatus.parse(status);

  String? get domain => fqdn;

  String get sourceLabel {
    if (gitRepository != null && gitRepository!.isNotEmpty) return gitRepository!;
    if (dockerRegistryImageName != null && dockerRegistryImageName!.isNotEmpty) {
      return dockerRegistryImageName!;
    }
    return buildPack ?? '—';
  }

  factory Application.fromJson(Map<String, dynamic> m) => Application(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        fqdn: jsonStr(m, 'fqdn'),
        status: jsonStr(m, 'status'),
        gitRepository: jsonStr(m, 'git_repository'),
        gitBranch: jsonStr(m, 'git_branch'),
        gitCommitSha: jsonStr(m, 'git_commit_sha'),
        buildPack: jsonStr(m, 'build_pack'),
        dockerRegistryImageName: jsonStr(m, 'docker_registry_image_name'),
        dockerRegistryImageTag: jsonStr(m, 'docker_registry_image_tag'),
        staticImage: jsonStr(m, 'static_image'),
        portsExposes: jsonStr(m, 'ports_exposes'),
        portsMappings: jsonStr(m, 'ports_mappings'),
        baseDirectory: jsonStr(m, 'base_directory'),
        publishDirectory: jsonStr(m, 'publish_directory'),
        description: jsonStr(m, 'description'),
        healthCheckEnabled: jsonBool(m, 'health_check_enabled'),
        healthCheckPath: jsonStr(m, 'health_check_path'),
        redirect: jsonStr(m, 'redirect'),
        isHttpBasicAuthEnabled: jsonBool(m, 'is_http_basic_auth_enabled'),
        dockerComposeLocation: jsonStr(m, 'docker_compose_location'),
        dockerComposeDomains: jsonStr(m, 'docker_compose_domains'),
        previewUrlTemplate: jsonStr(m, 'preview_url_template'),
        createdAt: jsonDt(m, 'created_at'),
        updatedAt: jsonDt(m, 'updated_at'),
        lastOnlineAt: jsonDt(m, 'last_online_at'),
        containerPresent: jsonBool(m, 'container_present'),
        noindexDomains: jsonStr(m, 'noindex_domains'),
        serverStatus: jsonBool(m, 'server_status'),
        customDockerRunOptions: jsonStr(m, 'custom_docker_run_options'),
        autoDeployEnabled: jsonBool(m, 'auto_deploy_enabled'),
        isStatic: jsonBool(m, 'is_static'),
        isSpa: jsonBool(m, 'is_spa'),
      );
}