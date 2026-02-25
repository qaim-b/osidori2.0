import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/transaction_source.dart';
import '../datasources/supabase_client.dart';
import '../models/recurring_rule_model.dart';

class RecurringRuleRepository {
  final SupabaseClient _client = AppSupabase.client;

  Future<List<RecurringRuleModel>> getForUser({
    required String userId,
    required List<String> groupIds,
  }) async {
    final own = await _client
        .from(AppSupabase.recurringRulesTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (groupIds.isEmpty) {
      return own.map((e) => RecurringRuleModel.fromJson(e)).toList();
    }

    final shared = await _client
        .from(AppSupabase.recurringRulesTable)
        .select()
        .neq('user_id', userId)
        .eq('visibility', 'shared')
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false);

    final merged = [...own, ...shared];
    final dedup = <String, Map<String, dynamic>>{};
    for (final row in merged) {
      dedup[row['id'] as String] = row;
    }
    return dedup.values.map((e) => RecurringRuleModel.fromJson(e)).toList();
  }

  Future<void> create(RecurringRuleModel model) async {
    await _client.from(AppSupabase.recurringRulesTable).insert(model.toJson());
  }

  Future<void> update(RecurringRuleModel model) async {
    await _client
        .from(AppSupabase.recurringRulesTable)
        .update(model.toJson())
        .eq('id', model.id);
  }

  Future<void> delete(String id) async {
    await _client.from(AppSupabase.recurringRulesTable).delete().eq('id', id);
  }

  Future<int> generateDueTransactions({
    required String userId,
    required List<String> groupIds,
    required DateTime until,
  }) async {
    final rules = await getForUser(userId: userId, groupIds: groupIds);
    var insertedCount = 0;

    for (final rule in rules.where((r) => r.isActive)) {
      final last =
          rule.lastGeneratedDate ??
          rule.startDate.subtract(const Duration(days: 1));
      var next = _nextDateAfter(
        last,
        rule.frequency,
        rule.intervalCount,
        rule.startDate,
      );
      final end = rule.endDate;

      while (!next.isAfter(until)) {
        if (next.isBefore(rule.startDate)) {
          next = _addCycle(next, rule.frequency, rule.intervalCount);
          continue;
        }
        if (end != null && next.isAfter(end)) {
          break;
        }

        final occurrenceDate = _dateOnly(next);
        final exists = await _client
            .from(AppSupabase.transactionsTable)
            .select('id')
            .eq('recurring_rule_id', rule.id)
            .eq('recurrence_occurrence_date', occurrenceDate)
            .maybeSingle();

        if (exists == null) {
          await _client.from(AppSupabase.transactionsTable).insert({
            'type': rule.type.name,
            'amount': rule.amount,
            'currency': rule.currency,
            'date': DateTime(
              next.year,
              next.month,
              next.day,
              9,
              0,
            ).toIso8601String(),
            'category_id': rule.categoryId,
            'from_account_id': rule.fromAccountId,
            'to_account_id': rule.toAccountId,
            'note': rule.note,
            'visibility': rule.visibility.name,
            'owner_user_id': rule.userId,
            'group_id': rule.visibility.name == 'shared' ? rule.groupId : null,
            'source': TransactionSource.recurring.name,
            'recurring_rule_id': rule.id,
            'recurrence_occurrence_date': occurrenceDate,
          });
          insertedCount++;
        }

        next = _addCycle(next, rule.frequency, rule.intervalCount);
      }

      final lastGenerated = _lastGeneratedFor(rule, until);
      if (lastGenerated != null &&
          (rule.lastGeneratedDate == null ||
              lastGenerated.isAfter(rule.lastGeneratedDate!))) {
        await _client
            .from(AppSupabase.recurringRulesTable)
            .update({'last_generated_date': _dateOnly(lastGenerated)})
            .eq('id', rule.id);
      }
    }

    return insertedCount;
  }

  DateTime? _lastGeneratedFor(RecurringRuleModel rule, DateTime until) {
    var d = _nextDateAfter(
      rule.lastGeneratedDate ??
          rule.startDate.subtract(const Duration(days: 1)),
      rule.frequency,
      rule.intervalCount,
      rule.startDate,
    );
    DateTime? latest;
    while (!d.isAfter(until)) {
      if (rule.endDate != null && d.isAfter(rule.endDate!)) break;
      if (!d.isBefore(rule.startDate)) latest = d;
      d = _addCycle(d, rule.frequency, rule.intervalCount);
    }
    return latest;
  }

  DateTime _nextDateAfter(
    DateTime base,
    RecurrenceFrequency frequency,
    int interval,
    DateTime anchor,
  ) {
    var next = _addCycle(base, frequency, interval);
    if (next.isBefore(anchor)) next = anchor;
    return DateTime(next.year, next.month, next.day);
  }

  DateTime _addCycle(
    DateTime date,
    RecurrenceFrequency frequency,
    int interval,
  ) {
    switch (frequency) {
      case RecurrenceFrequency.weekly:
        return date.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + interval, date.day);
      case RecurrenceFrequency.yearly:
        return DateTime(date.year + interval, date.month, date.day);
    }
  }

  String _dateOnly(DateTime date) {
    final d = date.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
