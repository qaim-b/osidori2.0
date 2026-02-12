import '../../domain/entities/goal_entity.dart';

class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.userId,
    super.groupId,
    required super.name,
    required super.emoji,
    required super.targetAmount,
    super.currentAmount,
    super.isCompleted,
    super.sortOrder,
    required super.createdAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '',
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'name': name,
      'emoji': emoji,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalModel.fromEntity(GoalEntity entity) {
    return GoalModel(
      id: entity.id,
      userId: entity.userId,
      groupId: entity.groupId,
      name: entity.name,
      emoji: entity.emoji,
      targetAmount: entity.targetAmount,
      currentAmount: entity.currentAmount,
      isCompleted: entity.isCompleted,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
    );
  }
}
