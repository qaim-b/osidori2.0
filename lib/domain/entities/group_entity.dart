/// A couple or small group that shares finances.
/// Initially exactly 2 members; later allows up to ~10.
class GroupEntity {
  final String id;
  final String name;
  final List<String> memberIds;
  final String createdByUserId;
  final DateTime createdAt;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.createdByUserId,
    required this.createdAt,
  });

  /// Quick check if a user belongs to this group
  bool hasMember(String userId) => memberIds.contains(userId);

  int get memberCount => memberIds.length;

  GroupEntity copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    String? createdByUserId,
    DateTime? createdAt,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
