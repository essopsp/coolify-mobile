import '../utils/json.dart';

class GithubApp {
  const GithubApp({
    this.uuid,
    this.name,
    this.organization,
    this.apiUrl,
    this.htmlUrl,
    this.isSystemWide,
    this.isPublic,
    this.type,
  });

  final String? uuid;
  final String? name;
  final String? organization;
  final String? apiUrl;
  final String? htmlUrl;
  final bool? isSystemWide;
  final bool? isPublic;
  final String? type;

  factory GithubApp.fromJson(Map<String, dynamic> m) => GithubApp(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        organization: jsonStr(m, 'organization'),
        apiUrl: jsonStr(m, 'api_url'),
        htmlUrl: jsonStr(m, 'html_url'),
        isSystemWide: jsonBool(m, 'is_system_wide'),
        isPublic: jsonBool(m, 'is_public'),
        type: jsonStr(m, 'type'),
      );
}

class GithubRepository {
  const GithubRepository({
    this.id,
    this.name,
    this.fullName,
    this.htmlUrl,
    this.isPrivate,
    this.defaultBranch,
  });

  final int? id;
  final String? name;
  final String? fullName;
  final String? htmlUrl;
  final bool? isPrivate;
  final String? defaultBranch;

  factory GithubRepository.fromJson(Map<String, dynamic> m) => GithubRepository(
        id: jsonInt(m, 'id'),
        name: jsonStr(m, 'name'),
        fullName: jsonStr(m, 'full_name'),
        htmlUrl: jsonStr(m, 'html_url'),
        isPrivate: jsonBool(m, 'private'),
        defaultBranch: jsonStr(m, 'default_branch'),
      );

  String get owner {
    final fn = fullName ?? '';
    final idx = fn.indexOf('/');
    return idx < 0 ? fn : fn.substring(0, idx);
  }

  String get repo {
    final fn = fullName ?? '';
    final idx = fn.indexOf('/');
    return idx < 0 ? '' : fn.substring(idx + 1);
  }
}

class GithubBranch {
  const GithubBranch({this.name, this.protected, this.commitSha});

  final String? name;
  final bool? protected;
  final String? commitSha;

  factory GithubBranch.fromJson(Map<String, dynamic> m) => GithubBranch(
        name: jsonStr(m, 'name'),
        protected: jsonBool(m, 'protected'),
        commitSha: jsonStr(m, 'commit_sha'),
      );
}