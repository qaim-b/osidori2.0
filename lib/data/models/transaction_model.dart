import '../../domain/entities/transaction_entity.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/enums/visibility_type.dart';
import '../../domain/enums/transaction_source.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.currency,
    required super.date,
    required super.categoryId,
    super.categoryNameSnapshot,
    super.categoryEmojiSnapshot,
    super.categoryDisplayNumberSnapshot,
    required super.fromAccountId,
    super.toAccountId,
    super.note,
    required super.visibility,
    required super.ownerUserId,
    super.groupId,
    super.source,
    super.recurringRuleId,
    super.recurrenceOccurrenceDate,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'JPY',
      date: DateTime.parse(json['date'] as String),
      categoryId: json['category_id'] as String,
      categoryNameSnapshot: json['category_name_snapshot'] as String?,
      categoryEmojiSnapshot: json['category_emoji_snapshot'] as String?,
      categoryDisplayNumberSnapshot:
          (json['category_display_number_snapshot'] as num?)?.toInt(),
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String?,
      note: json['note'] as String?,
      visibility: VisibilityType.fromString(json['visibility'] as String),
      ownerUserId: json['owner_user_id'] as String,
      groupId: json['group_id'] as String?,
      source: TransactionSource.fromString(
        json['source'] as String? ?? 'manual',
      ),
      recurringRuleId: json['recurring_rule_id'] as String?,
      recurrenceOccurrenceDate: json['recurrence_occurrence_date'] == null
          ? null
          : DateTime.parse(json['recurrence_occurrence_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'category_name_snapshot': categoryNameSnapshot,
      'category_emoji_snapshot': categoryEmojiSnapshot,
      'category_display_number_snapshot': categoryDisplayNumberSnapshot,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'note': note,
      'visibility': visibility.name,
      'owner_user_id': ownerUserId,
      'group_id': groupId,
      'source': source.name,
      'recurring_rule_id': recurringRuleId,
      'recurrence_occurrence_date': recurrenceOccurrenceDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      type: entity.type,
      amount: entity.amount,
      currency: entity.currency,
      date: entity.date,
      categoryId: entity.categoryId,
      categoryNameSnapshot: entity.categoryNameSnapshot,
      categoryEmojiSnapshot: entity.categoryEmojiSnapshot,
      categoryDisplayNumberSnapshot: entity.categoryDisplayNumberSnapshot,
      fromAccountId: entity.fromAccountId,
      toAccountId: entity.toAccountId,
      note: entity.note,
      visibility: entity.visibility,
      ownerUserId: entity.ownerUserId,
      groupId: entity.groupId,
      source: entity.source,
      recurringRuleId: entity.recurringRuleId,
      recurrenceOccurrenceDate: entity.recurrenceOccurrenceDate,
      createdAt: entity.createdAt,
    );
  }
}
