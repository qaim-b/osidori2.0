/// Core user entity — decoupled from any backend specifics.
/// role: 'stitch', 'angel', 'solo' or null (not chosen yet)
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? role; // 'stitch' or 'angel' or 'solo'
  final String preferredCurrency;
  final String fxDisplayMode; // 'accounting' | 'live'
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.role,
    this.preferredCurrency = 'JPY',
    this.fxDisplayMode = 'accounting',
    required this.createdAt,
  });

  bool get isStitch => role == 'stitch';
  bool get isAngel => role == 'angel';
  bool get isSolo => role == 'solo';
  bool get hasRole => role != null;

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? role,
    String? preferredCurrency,
    String? fxDisplayMode,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      fxDisplayMode: fxDisplayMode ?? this.fxDisplayMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
