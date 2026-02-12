/// A budget limit for a category — set once, reused monthly.
class BudgetLimitEntity {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetLimitEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  BudgetLimitEntity copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetLimitEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetLimitEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
