import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/enums/recurrence_frequency.dart';
import '../datasources/supabase_client.dart';
import '../models/bill_reminder_model.dart';

class BillReminderRepository {
  final SupabaseClient _client = AppSupabase.client;

  Future<List<BillReminderModel>> getForUser({
    required String userId,
    required List<String> groupIds,
  }) async {
    final own = await _client
        .from(AppSupabase.billRemindersTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (groupIds.isEmpty) {
      return own.map((e) => BillReminderModel.fromJson(e)).toList();
    }

    final shared = await _client
        .from(AppSupabase.billRemindersTable)
        .select()
        .neq('user_id', userId)
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false);

    final merged = [...own, ...shared];
    final dedup = <String, Map<String, dynamic>>{};
    for (final row in merged) {
      dedup[row['id'] as String] = row;
    }
    return dedup.values.map((e) => BillReminderModel.fromJson(e)).toList();
  }

  Future<void> create(BillReminderModel model) async {
    await _client.from(AppSupabase.billRemindersTable).insert(model.toJson());
  }

  Future<void> update(BillReminderModel model) async {
    await _client
        .from(AppSupabase.billRemindersTable)
        .update(model.toJson())
        .eq('id', model.id);
  }

  Future<void> delete(String id) async {
    await _client.from(AppSupabase.billRemindersTable).delete().eq('id', id);
  }

  DateTime nextDueDate(BillReminderModel reminder, DateTime now) {
    var date = DateTime(
      reminder.anchorDate.year,
      reminder.anchorDate.month,
      reminder.anchorDate.day,
    );

    while (date.isBefore(DateTime(now.year, now.month, now.day))) {
      date = _advance(date, reminder.dueFrequency, reminder.dueIntervalCount);
    }
    return date;
  }

  DateTime _advance(DateTime date, RecurrenceFrequency freq, int interval) {
    switch (freq) {
      case RecurrenceFrequency.weekly:
        return date.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + interval, date.day);
      case RecurrenceFrequency.yearly:
        return DateTime(date.year + interval, date.month, date.day);
    }
  }
}
