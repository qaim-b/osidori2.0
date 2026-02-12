import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/models/goal_model.dart';
import 'auth_provider.dart';

final goalRepositoryProvider =
    Provider<GoalRepository>((ref) => GoalRepository());

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<List<GoalModel>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.read(goalRepositoryProvider);
  return GoalsNotifier(repo, userId);
});

class GoalsNotifier extends StateNotifier<AsyncValue<List<GoalModel>>> {
  final GoalRepository _repo;
  final String? _userId;
  static const _uuid = Uuid();
  static const maxGoals = 3;

  GoalsNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final goals = await _repo.getForUser(_userId);
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal({
    required String name,
    required String emoji,
    required double targetAmount,
    double currentAmount = 0,
    String? groupId,
  }) async {
    if (_userId == null) return;
    final current = state.valueOrNull ?? [];
    if (current.length >= maxGoals) return;

    final goal = GoalModel(
      id: _uuid.v4(),
      userId: _userId,
      groupId: groupId,
      name: name,
      emoji: emoji,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      sortOrder: current.length,
      createdAt: DateTime.now(),
    );

    await _repo.create(goal);
    await load();
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _repo.update(goal);
    await load();
  }

  Future<void> deleteGoal(String id) async {
    await _repo.delete(id);
    await load();
  }
}
