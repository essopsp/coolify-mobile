import '../utils/json.dart';

class Environment {
  const Environment({this.uuid, this.name, this.description});

  final String? uuid;
  final String? name;
  final String? description;

  factory Environment.fromJson(Map<String, dynamic> m) => Environment(
        uuid: jsonStr(m, 'uuid'),
        name: jsonStr(m, 'name'),
        description: jsonStr(m, 'description'),
      );
}

class EnvVar {
  const EnvVar({
    this.id,
    this.uuid,
    this.key,
    this.value,
    this.isBuildTime,
    this.isPreview,
    this.isRuntime,
    this.isLiteral,
    this.isMultiline,
    this.isShownOnce,
    this.comment,
  });

  final int? id;
  final String? uuid;
  final String? key;
  final String? value;
  final bool? isBuildTime;
  final bool? isPreview;
  final bool? isRuntime;
  final bool? isLiteral;
  final bool? isMultiline;
  final bool? isShownOnce;
  final String? comment;

  String? get effectiveUuid => uuid;

  bool get isSecret {
    final k = key;
    return value == null &&
        k != null &&
        (k.contains('SECRET') ||
            k.contains('PASSWORD') ||
            k.contains('TOKEN') ||
            k.contains('KEY'));
  }

  factory EnvVar.fromJson(Map<String, dynamic> m) => EnvVar(
        id: jsonInt(m, 'id'),
        uuid: jsonStr(m, 'uuid'),
        key: jsonStr(m, 'key'),
        value: jsonStr(m, 'value'),
        isBuildTime: jsonBool(m, 'is_build_time') ?? jsonBool(m, 'is_buildtime'),
        isPreview: jsonBool(m, 'is_preview'),
        isRuntime: jsonBool(m, 'is_runtime') ?? jsonBool(m, 'is_build_time'),
        isLiteral: jsonBool(m, 'is_literal'),
        isMultiline: jsonBool(m, 'is_multiline'),
        isShownOnce: jsonBool(m, 'is_shown_once'),
        comment: jsonStr(m, 'comment'),
      );
}