import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/budget_limit_repository.dart';
import '../../data/models/budget_limit_model.dart';
import 'auth_provider.dart';

final budgetLimitRepositoryProvider =
    Provider<BudgetLimitRepository>((ref) => BudgetLimitRepository());

final budgetLimitsProvider = StateNotifierProvider<BudgetLimitsNotifier,
    AsyncValue<List<BudgetLimitModel>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.read(budgetLimitRepositoryProvider);
  return BudgetLimitsNotifier(repo, userId);
});

/// Convenient map: categoryId → budget limit amount
final budgetLimitMapProvider = Provider<Map<String, double>>((ref) {
  final limits = ref.watch(budgetLimitsProvider).valueOrNull ?? [];
  return {for (final l in limits) l.categoryId: l.amount};
});

class BudgetLimitsNotifier
    extends StateNotifier<AsyncValue<List<BudgetLimitModel>>> {
  final BudgetLimitRepository _repo;
  final String? _userId;
  static const _uuid = Uuid();

  BudgetLimitsNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final limits = await _repo.getForUser(_userId);
      state = AsyncValue.data(limits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setLimit({
    required String categoryId,
    required double amount,
  }) async {
    if (_userId == null) return;

    final now = DateTime.now();
    final existing = state.valueOrNull
        ?.where((l) => l.categoryId == categoryId)
        .firstOrNull;

    final limit = BudgetLimitModel(
      id: existing?.id ?? _uuid.v4(),
      userId: _userId,
      categoryId: categoryId,
      amount: amount,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _repo.upsert(limit);
    await load();
  }

  Future<void> removeLimit(String id) async {
    await _repo.delete(id);
    await load();
  }
}
