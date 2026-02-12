/// A shared financial goal (e.g. "Hawaii trip", "Emergency fund").
/// Max 3 goals per user/group.
class GoalEntity {
  final String id;
  final String userId;
  final String? groupId;
  final String name;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final bool isCompleted;
  final int sortOrder;
  final DateTime createdAt;

  const GoalEntity({
    required this.id,
    required this.userId,
    this.groupId,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    this.currentAmount = 0,
    this.isCompleted = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  GoalEntity copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? name,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    bool? isCompleted,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GoalEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
