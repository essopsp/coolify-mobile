import 'dart:convert';

enum ApiErrorKind {
  unauthenticated,
  forbidden,
  notFound,
  badRequest,
  rateLimited,
  network,
  server,
  empty,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.kind, this.message, {this.statusCode, this.details});

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  bool get isAuthError =>
      kind == ApiErrorKind.unauthenticated || kind == ApiErrorKind.forbidden;

  bool get isRateLimited => kind == ApiErrorKind.rateLimited;

  @override
  String toString() => message;

  factory ApiException.fromStatus(int code, String body) {
    final kind = switch (code) {
      401 => ApiErrorKind.unauthenticated,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      400 || 422 => ApiErrorKind.badRequest,
      429 => ApiErrorKind.rateLimited,
      _ when code >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };
    final fallback = switch (kind) {
      ApiErrorKind.unauthenticated =>
        'Invalid or expired token. Check your API token.',
      ApiErrorKind.forbidden =>
        'Forbidden. The token may lack required permissions '
            '(e.g. read:sensitive for logs).',
      ApiErrorKind.notFound => 'Resource not found.',
      ApiErrorKind.badRequest => 'Bad request (HTTP $code).',
      ApiErrorKind.rateLimited =>
        'Rate limit reached (HTTP 429). Please wait and retry.',
      ApiErrorKind.server => 'Coolify server error (HTTP $code).',
      _ => 'Request failed (HTTP $code).',
    };
    return ApiException(kind, _extractMessage(body) ?? fallback, statusCode: code);
  }

  /// Best-effort extraction of a `message` / `error` field from a JSON body.
  static String? _extractMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final dec = jsonDecode(body);
      Object? probe = dec;
      if (probe is Map<String, dynamic>) {
        probe = probe['message'] ?? probe['error'] ?? probe['errors'];
      } else if (probe is List && probe.isNotEmpty) {
        probe = probe.first;
        if (probe is Map<String, dynamic>) {
          probe = probe['message'] ?? probe['error'];
        }
      }
      if (probe is String && probe.trim().isNotEmpty) return probe.trim();
      if (probe is Map) {
        return probe.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
      }
      return null;
    } catch (_) {
      final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(body);
      if (match != null) return match.group(1);
      return null;
    }
  }
}