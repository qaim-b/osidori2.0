import '../enums/recurrence_frequency.dart';

class BillReminderEntity {
  final String id;
  final String userId;
  final String? groupId;
  final String? recurringRuleId;
  final String title;
  final double? amount;
  final String currency;
  final RecurrenceFrequency dueFrequency;
  final int dueIntervalCount;
  final DateTime anchorDate;
  final List<int> reminderDaysBefore;
  final bool sendOverdue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillReminderEntity({
    required this.id,
    required this.userId,
    this.groupId,
    this.recurringRuleId,
    required this.title,
    this.amount,
    required this.currency,
    required this.dueFrequency,
    this.dueIntervalCount = 1,
    required this.anchorDate,
    this.reminderDaysBefore = const [7, 2, 0],
    this.sendOverdue = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  BillReminderEntity copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? recurringRuleId,
    String? title,
    double? amount,
    String? currency,
    RecurrenceFrequency? dueFrequency,
    int? dueIntervalCount,
    DateTime? anchorDate,
    List<int>? reminderDaysBefore,
    bool? sendOverdue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillReminderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueFrequency: dueFrequency ?? this.dueFrequency,
      dueIntervalCount: dueIntervalCount ?? this.dueIntervalCount,
      anchorDate: anchorDate ?? this.anchorDate,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      sendOverdue: sendOverdue ?? this.sendOverdue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
