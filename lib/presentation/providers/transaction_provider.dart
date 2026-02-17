import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/enums/visibility_type.dart';
import '../../domain/enums/transaction_source.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

/// Selected month for overview/reports — defaults to current month
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Visibility filter: null = all, 'personal', 'shared'
final visibilityFilterProvider = StateProvider<String?>((ref) => null);

/// Transactions for the selected month
final monthlyTransactionsProvider =
    StateNotifierProvider<
      TransactionsNotifier,
      AsyncValue<List<TransactionModel>>
    >((ref) {
      final userId = ref.watch(currentUserIdProvider);
      final groupIds = ref.watch(groupIdsProvider);
      final selectedMonth = ref.watch(selectedMonthProvider);
      final repo = ref.read(transactionRepositoryProvider);
      return TransactionsNotifier(
        repo,
        userId,
        selectedMonth,
        groupIds,
      );
    });

class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final TransactionRepository _repo;
  final String? _userId;
  final DateTime _month;
  final List<String> _groupIds;
  static const _uuid = Uuid();

  TransactionsNotifier(
    this._repo,
    this._userId,
    this._month,
    this._groupIds,
  ) : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final from = DateTime(_month.year, _month.month, 1);
      final to = DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);
      final txns = await _repo.getForUser(
        userId: _userId,
        groupIds: _groupIds,
        from: from,
        to: to,
      );
      state = AsyncValue.data(txns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction({
    required TransactionType type,
    required double amount,
    required String currency,
    required DateTime date,
    required String categoryId,
    String? categoryNameSnapshot,
    String? categoryEmojiSnapshot,
    int? categoryDisplayNumberSnapshot,
    required String fromAccountId,
    String? toAccountId,
    String? note,
    required VisibilityType visibility,
    String? groupId,
  }) async {
    if (_userId == null) return;
    final resolvedGroupId =
        groupId ?? (_groupIds.isEmpty ? null : _groupIds.first);
    if (visibility == VisibilityType.shared && resolvedGroupId == null) {
      throw Exception(
        'No active group found. Connect your partner in Settings first.',
      );
    }

    final txn = TransactionModel(
      id: _uuid.v4(),
      type: type,
      amount: amount,
      currency: currency,
      date: date,
      categoryId: categoryId,
      categoryNameSnapshot: categoryNameSnapshot,
      categoryEmojiSnapshot: categoryEmojiSnapshot,
      categoryDisplayNumberSnapshot: categoryDisplayNumberSnapshot,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      note: note,
      visibility: visibility,
      ownerUserId: _userId,
      groupId: resolvedGroupId,
      source: TransactionSource.manual,
      createdAt: DateTime.now(),
    );

    await _repo.create(txn);
    await load();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    await _repo.update(txn);
    await load();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.delete(id);
    await load();
  }
}

/// Monthly totals for the overview
final monthlyTotalsProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  final visibility = ref.watch(visibilityFilterProvider);

  Iterable<TransactionModel> filtered = txns;
  if (visibility != null) {
    filtered = filtered.where((t) => t.visibility.name == visibility);
  }

  double income = 0;
  double expense = 0;
  for (final txn in filtered) {
    if (txn.isIncome) income += txn.amount;
    if (txn.isExpense) expense += txn.amount;
  }

  return {'income': income, 'expense': expense, 'net': income - expense};
});

/// Category totals for the donut chart
final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  final visibility = ref.watch(visibilityFilterProvider);

  Iterable<TransactionModel> filtered = txns.where((t) => t.isExpense);
  if (visibility != null) {
    filtered = filtered.where((t) => t.visibility.name == visibility);
  }

  final totals = <String, double>{};
  for (final txn in filtered) {
    totals[txn.categoryId] = (totals[txn.categoryId] ?? 0) + txn.amount;
  }
  return totals;
});
