import '../../domain/entities/budget_limit_entity.dart';

class BudgetLimitModel extends BudgetLimitEntity {
  const BudgetLimitModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.amount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BudgetLimitModel.fromJson(Map<String, dynamic> json) {
    return BudgetLimitModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BudgetLimitModel.fromEntity(BudgetLimitEntity entity) {
    return BudgetLimitModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      amount: entity.amount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
