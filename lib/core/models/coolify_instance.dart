import '../utils/json.dart';

/// A stored Coolify connection (not an API type). Persisted in secure storage.
class CoolifyInstance {
  const CoolifyInstance({
    required this.id,
    required this.name,
    required this.url,
    required this.token,
  });

  final String id;
  final String name;
  final String url;
  final String token;

  String get baseUrl {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return '$u/api/v1';
  }

  String get host {
    return url.replaceAll(RegExp(r'^https?://'), '').split('/').first;
  }

  CoolifyInstance copyWith({String? name, String? url, String? token}) =>
      CoolifyInstance(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
        token: token ?? this.token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'token': token,
      };

  factory CoolifyInstance.fromJson(Map<String, dynamic> m) => CoolifyInstance(
        id: jsonStrOr(m, 'id'),
        name: jsonStrOr(m, 'name', 'Coolify'),
        url: jsonStrOr(m, 'url'),
        token: jsonStrOr(m, 'token'),
      );
}