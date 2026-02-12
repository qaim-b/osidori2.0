/// Core user entity — decoupled from any backend specifics.
/// role: 'stitch' (boy/blue) or 'angel' (girl/pink) or null (not chosen yet)
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? role; // 'stitch' or 'angel'
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.role,
    required this.createdAt,
  });

  bool get isStitch => role == 'stitch';
  bool get isAngel => role == 'angel';
  bool get hasRole => role != null;

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
