import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/models/category_model.dart';
import 'auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>(
        (ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.read(categoryRepositoryProvider);
  return CategoriesNotifier(repo, userId);
});

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository _repo;
  final String? _userId;

  CategoriesNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final categories = await _repo.getAll(_userId);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleEnabled(String categoryId, bool enabled) async {
    await _repo.toggleEnabled(categoryId, enabled);
    await load();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _repo.update(category);
    await load();
  }

  /// Get only enabled expense categories, sorted by displayNumber
  List<CategoryModel> get enabledExpenseCategories {
    final cats = state.valueOrNull ?? [];
    return cats
        .where((c) => c.isExpense && c.isEnabled)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get only enabled income categories
  List<CategoryModel> get enabledIncomeCategories {
    final cats = state.valueOrNull ?? [];
    return cats
        .where((c) => c.isIncome && c.isEnabled)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
