import '../../domain/entities/bill_reminder_entity.dart';
import '../../domain/enums/recurrence_frequency.dart';

class BillReminderModel extends BillReminderEntity {
  const BillReminderModel({
    required super.id,
    required super.userId,
    super.groupId,
    super.recurringRuleId,
    required super.title,
    super.amount,
    required super.currency,
    required super.dueFrequency,
    super.dueIntervalCount,
    required super.anchorDate,
    super.reminderDaysBefore,
    super.sendOverdue,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BillReminderModel.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['reminder_days_before'] as List?) ?? const [7, 2, 0];
    return BillReminderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      recurringRuleId: json['recurring_rule_id'] as String?,
      title: json['title'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'JPY',
      dueFrequency: RecurrenceFrequency.fromString(
        json['due_frequency'] as String,
      ),
      dueIntervalCount: (json['due_interval_count'] as num?)?.toInt() ?? 1,
      anchorDate: DateTime.parse(json['anchor_date'] as String),
      reminderDaysBefore: rawDays.map((e) => (e as num).toInt()).toList(),
      sendOverdue: json['send_overdue'] as bool? ?? true,
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
      'recurring_rule_id': recurringRuleId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'due_frequency': dueFrequency.name,
      'due_interval_count': dueIntervalCount,
      'anchor_date': _dateOnly(anchorDate),
      'reminder_days_before': reminderDaysBefore,
      'send_overdue': sendOverdue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _dateOnly(DateTime date) {
    final d = date.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  BillReminderModel copyWithModel({
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
    return BillReminderModel(
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
