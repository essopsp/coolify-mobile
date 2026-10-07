import '../utils/json.dart';

class Team {
  const Team({this.id, this.name, this.description});

  final int? id;
  final String? name;
  final String? description;

  factory Team.fromJson(Map<String, dynamic> m) => Team(
        id: jsonInt(m, 'id'),
        name: jsonStr(m, 'name'),
        description: jsonStr(m, 'description'),
      );
}

class TeamMember {
  const TeamMember({
    this.id,
    this.name,
    this.email,
    this.role,
    this.isOwner,
    this.twoFactorEnabled,
    this.createdAt,
  });

  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final bool? isOwner;
  final bool? twoFactorEnabled;
  final DateTime? createdAt;

  factory TeamMember.fromJson(Map<String, dynamic> m) => TeamMember(
        id: jsonInt(m, 'id'),
        name: jsonStr(m, 'name') ?? jsonStr(m, 'username'),
        email: jsonStr(m, 'email'),
        role: jsonStr(m, 'role'),
        isOwner: jsonBool(m, 'is_owner'),
        twoFactorEnabled: jsonBool(m, 'two_factor_enabled'),
        createdAt: jsonDt(m, 'created_at'),
      );
}