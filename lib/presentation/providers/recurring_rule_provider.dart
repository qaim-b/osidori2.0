import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/recurring_rule_model.dart';
import '../../data/repositories/recurring_rule_repository.dart';
import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/enums/visibility_type.dart';
import 'auth_provider.dart';
import 'group_provider.dart';
import 'transaction_provider.dart';

final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>(
  (ref) => RecurringRuleRepository(),
);

final recurringRulesProvider =
    StateNotifierProvider<
      RecurringRulesNotifier,
      AsyncValue<List<RecurringRuleModel>>
    >((ref) {
      final repo = ref.read(recurringRuleRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      final groupIds = ref.watch(groupIdsProvider);
      return RecurringRulesNotifier(ref, repo, userId, groupIds);
    });

class RecurringRulesNotifier
    extends StateNotifier<AsyncValue<List<RecurringRuleModel>>> {
  final Ref _ref;
  final RecurringRuleRepository _repo;
  final String? _userId;
  final List<String> _groupIds;
  static const _uuid = Uuid();

  RecurringRulesNotifier(this._ref, this._repo, this._userId, this._groupIds)
    : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getForUser(
        userId: _userId,
        groupIds: _groupIds,
      );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRule({
    required String name,
    required TransactionType type,
    required double amount,
    required String currency,
    required String categoryId,
    required String fromAccountId,
    String? toAccountId,
    String? note,
    required VisibilityType visibility,
    required RecurrenceFrequency frequency,
    required int intervalCount,
    required DateTime startDate,
    DateTime? endDate,
    String? groupId,
  }) async {
    if (_userId == null) return;
    final rule = RecurringRuleModel(
      id: _uuid.v4(),
      userId: _userId,
      groupId: visibility == VisibilityType.shared
          ? (groupId ?? (_groupIds.isEmpty ? null : _groupIds.first))
          : null,
      name: name,
      type: type,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      note: note,
      visibility: visibility,
      frequency: frequency,
      intervalCount: intervalCount,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.create(rule);
    await load();
    await generateCatchUp(until: DateTime.now());
  }

  Future<void> updateRule(RecurringRuleModel rule) async {
    await _repo.update(rule.copyWithModel(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> deleteRule(String id) async {
    await _repo.delete(id);
    await load();
  }

  Future<int> generateCatchUp({DateTime? until}) async {
    if (_userId == null) return 0;
    final count = await _repo.generateDueTransactions(
      userId: _userId,
      groupIds: _groupIds,
      until: until ?? DateTime.now(),
    );
    if (count > 0) {
      await _ref.read(monthlyTransactionsProvider.notifier).load();
    }
    return count;
  }
}
