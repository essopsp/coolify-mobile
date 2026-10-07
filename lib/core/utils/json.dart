String? jsonStr(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v == null) return null;
  return v is String ? v : v.toString();
}

String jsonStrOr(Map<String, dynamic> m, String k, [String fallback = '']) {
  final v = m[k];
  if (v == null) return fallback;
  return v is String ? v : v.toString();
}

int? jsonInt(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

int jsonIntOr(Map<String, dynamic> m, String k, [int fallback = 0]) =>
    jsonInt(m, k) ?? fallback;

double? jsonDouble(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool? jsonBool(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

bool jsonBoolOr(Map<String, dynamic> m, String k, [bool fallback = false]) =>
    jsonBool(m, k) ?? fallback;

DateTime? jsonDt(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v == null || v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v)?.toLocal() ??
      DateTime.tryParse(v.replaceAll(' ', 'T'))?.toLocal();
}

Map<String, dynamic>? jsonMap(Map<String, dynamic> m, String k) {
  final v = m[k];
  return v is Map<String, dynamic> ? v : null;
}

List<Map<String, dynamic>> jsonList(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

List<String> jsonStrList(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v is! List) return const [];
  return v.whereType<String>().toList(growable: false);
}

List<T> jsonListCast<T>(Map<String, dynamic> m, String k,
    T Function(Map<String, dynamic>) parser) {
  return jsonList(m, k).map(parser).toList(growable: false);
}