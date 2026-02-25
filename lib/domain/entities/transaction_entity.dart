import '../enums/transaction_type.dart';
import '../enums/visibility_type.dart';
import '../enums/transaction_source.dart';

/// THE most important entity in the app.
/// Every financial event is a Transaction.
///
/// Rules:
/// - Expenses reduce balance
/// - Income increases balance
/// - Transfers move money between accounts (net-worth neutral)
/// - amount is ALWAYS positive; the type determines the direction
class TransactionEntity implements Comparable<TransactionEntity> {
  final String id;
  final TransactionType type;
  final double amount;
  final String currency;
  final DateTime date;
  final String categoryId;
  final String? categoryNameSnapshot;
  final String? categoryEmojiSnapshot;
  final int? categoryDisplayNumberSnapshot;
  final String fromAccountId;
  final String? toAccountId; // Only for transfers
  final String? note;
  final VisibilityType visibility;
  final String ownerUserId;
  final String? groupId;
  final TransactionSource source;
  final String? recurringRuleId;
  final DateTime? recurrenceOccurrenceDate;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.categoryId,
    this.categoryNameSnapshot,
    this.categoryEmojiSnapshot,
    this.categoryDisplayNumberSnapshot,
    required this.fromAccountId,
    this.toAccountId,
    this.note,
    required this.visibility,
    required this.ownerUserId,
    this.groupId,
    this.source = TransactionSource.manual,
    this.recurringRuleId,
    this.recurrenceOccurrenceDate,
    required this.createdAt,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;
  bool get isPersonal => visibility == VisibilityType.personal;
  bool get isShared => visibility == VisibilityType.shared;

  /// Signed amount: negative for expenses, positive for income.
  /// Transfers return 0 (net-worth neutral).
  double get signedAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount;
      case TransactionType.income:
        return amount;
      case TransactionType.transfer:
        return 0;
    }
  }

  TransactionEntity copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? currency,
    DateTime? date,
    String? categoryId,
    String? categoryNameSnapshot,
    String? categoryEmojiSnapshot,
    int? categoryDisplayNumberSnapshot,
    String? fromAccountId,
    String? toAccountId,
    String? note,
    VisibilityType? visibility,
    String? ownerUserId,
    String? groupId,
    TransactionSource? source,
    String? recurringRuleId,
    DateTime? recurrenceOccurrenceDate,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      categoryEmojiSnapshot:
          categoryEmojiSnapshot ?? this.categoryEmojiSnapshot,
      categoryDisplayNumberSnapshot:
          categoryDisplayNumberSnapshot ?? this.categoryDisplayNumberSnapshot,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      visibility: visibility ?? this.visibility,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      groupId: groupId ?? this.groupId,
      source: source ?? this.source,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      recurrenceOccurrenceDate:
          recurrenceOccurrenceDate ?? this.recurrenceOccurrenceDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Sort by date descending (newest first)
  @override
  int compareTo(TransactionEntity other) => other.date.compareTo(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransactionEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
