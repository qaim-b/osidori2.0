import '../../domain/entities/group_entity.dart';

class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    required super.memberIds,
    required super.createdByUserId,
    required super.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      memberIds: List<String>.from(json['member_ids'] ?? []),
      createdByUserId: json['created_by_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'member_ids': memberIds,
      'created_by_user_id': createdByUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      memberIds: entity.memberIds,
      createdByUserId: entity.createdByUserId,
      createdAt: entity.createdAt,
    );
  }
}
