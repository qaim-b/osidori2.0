import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/enums/visibility_type.dart';
import '../../domain/enums/transaction_source.dart';
import 'auth_provider.dart';
import 'account_provider.dart';
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
      final accountRepo = ref.read(accountRepositoryProvider);
      return TransactionsNotifier(
        ref,
        repo,
        accountRepo,
        userId,
        selectedMonth,
        groupIds,
      );
    });

class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final Ref _ref;
  final TransactionRepository _repo;
  final AccountRepository _accountRepo;
  final String? _userId;
  final DateTime _month;
  final List<String> _groupIds;
  static const _uuid = Uuid();

  TransactionsNotifier(
    this._ref,
    this._repo,
    this._accountRepo,
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
    await _applyTransactionBalanceImpact(txn, reverse: false);
    await load();
    await _ref.read(accountsProvider.notifier).load();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    final previous = state.valueOrNull
        ?.where((t) => t.id == txn.id)
        .firstOrNull;
    await _repo.update(txn);
    if (previous != null) {
      await _applyTransactionBalanceImpact(previous, reverse: true);
      await _applyTransactionBalanceImpact(txn, reverse: false);
    }
    await load();
    await _ref.read(accountsProvider.notifier).load();
  }

  Future<void> deleteTransaction(String id) async {
    final previous = state.valueOrNull?.where((t) => t.id == id).firstOrNull;
    await _repo.delete(id);
    if (previous != null) {
      await _applyTransactionBalanceImpact(previous, reverse: true);
    }
    await load();
    await _ref.read(accountsProvider.notifier).load();
  }

  Future<void> _applyTransactionBalanceImpact(
    TransactionModel txn, {
    required bool reverse,
  }) async {
    final signedAmount = txn.amount * (reverse ? -1 : 1);
    if (txn.isExpense) {
      await _adjustAccountBalance(txn.fromAccountId, -signedAmount);
      return;
    }
    if (txn.isIncome) {
      await _adjustAccountBalance(txn.fromAccountId, signedAmount);
      return;
    }
    if (txn.isTransfer) {
      await _adjustAccountBalance(txn.fromAccountId, -signedAmount);
      if (txn.toAccountId != null) {
        await _adjustAccountBalance(txn.toAccountId!, signedAmount);
      }
    }
  }

  Future<void> _adjustAccountBalance(String accountId, double delta) async {
    if (_userId == null || delta == 0) return;
    try {
      AccountModel? account = _ref
          .read(accountsProvider)
          .valueOrNull
          ?.where((a) => a.id == accountId)
          .firstOrNull;
      account ??= await _accountRepo.getById(accountId);
      if (account == null) return;

      var nextBalance = account.initialBalance + delta;
      if (nextBalance < 0) {
        nextBalance = 0;
      }
      if ((nextBalance - account.initialBalance).abs() < 0.0001) {
        return;
      }

      await _accountRepo.update(
        AccountModel(
          id: account.id,
          name: account.name,
          type: account.type,
          ownerScope: account.ownerScope,
          ownerUserId: account.ownerUserId,
          groupId: account.groupId,
          currency: account.currency,
          initialBalance: nextBalance,
          createdAt: account.createdAt,
        ),
      );
    } catch (_) {
      // Never block transaction creation/edit/deletion because of balance sync.
    }
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
