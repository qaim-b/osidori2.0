import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/enums/visibility_type.dart';

class RecurringRuleModel extends RecurringRuleEntity {
  const RecurringRuleModel({
    required super.id,
    required super.userId,
    super.groupId,
    required super.name,
    required super.type,
    required super.amount,
    required super.currency,
    required super.categoryId,
    required super.fromAccountId,
    super.toAccountId,
    super.note,
    required super.visibility,
    required super.frequency,
    super.intervalCount,
    required super.startDate,
    super.endDate,
    super.lastGeneratedDate,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) {
    return RecurringRuleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      name: json['name'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'JPY',
      categoryId: json['category_id'] as String,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String?,
      note: json['note'] as String?,
      visibility: VisibilityType.fromString(json['visibility'] as String),
      frequency: RecurrenceFrequency.fromString(json['frequency'] as String),
      intervalCount: (json['interval_count'] as num?)?.toInt() ?? 1,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      lastGeneratedDate: json['last_generated_date'] == null
          ? null
          : DateTime.parse(json['last_generated_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'name': name,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'category_id': categoryId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'note': note,
      'visibility': visibility.name,
      'frequency': frequency.name,
      'interval_count': intervalCount,
      'start_date': _dateOnly(startDate),
      'end_date': endDate == null ? null : _dateOnly(endDate!),
      'last_generated_date': lastGeneratedDate == null
          ? null
          : _dateOnly(lastGeneratedDate!),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _dateOnly(DateTime date) {
    final d = date.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  RecurringRuleModel copyWithModel({
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
    return RecurringRuleModel(
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
