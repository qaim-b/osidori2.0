import '../enums/recurrence_frequency.dart';
import '../enums/transaction_type.dart';
import '../enums/visibility_type.dart';

class RecurringRuleEntity {
  final String id;
  final String userId;
  final String? groupId;
  final String name;
  final TransactionType type;
  final double amount;
  final String currency;
  final String categoryId;
  final String fromAccountId;
  final String? toAccountId;
  final String? note;
  final VisibilityType visibility;
  final RecurrenceFrequency frequency;
  final int intervalCount;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringRuleEntity({
    required this.id,
    required this.userId,
    this.groupId,
    required this.name,
    required this.type,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.fromAccountId,
    this.toAccountId,
    this.note,
    required this.visibility,
    required this.frequency,
    this.intervalCount = 1,
    required this.startDate,
    this.endDate,
    this.lastGeneratedDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  RecurringRuleEntity copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? name,
    TransactionType? type,
    double? amount,
    String? currency,
    String? categoryId,
    String? fromAccountId,
    String? toAccountId,
    String? note,
    VisibilityType? visibility,
    RecurrenceFrequency? frequency,
    int? intervalCount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastGeneratedDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringRuleEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      visibility: visibility ?? this.visibility,
      frequency: frequency ?? this.frequency,
      intervalCount: intervalCount ?? this.intervalCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
