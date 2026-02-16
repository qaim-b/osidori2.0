import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../datasources/supabase_client.dart';
import '../models/category_model.dart';
import '../../core/constants/category_defaults.dart';

/// Manages categories — seeds defaults on first run, supports custom edits.
class CategoryRepository {
  final SupabaseClient _client = AppSupabase.client;
  static const _uuid = Uuid();

  /// Fetch all categories for a user.
  /// If none exist yet, seed the defaults.
  Future<List<CategoryModel>> getAll(String userId) async {
    final data = await _client
        .from(AppSupabase.categoriesTable)
        .select()
        .eq('user_id', userId)
        .order('sort_order');

    if (data.isEmpty) {
      return seedDefaults(userId);
    }

    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  /// Seed all default categories from the planning sheet.
  Future<List<CategoryModel>> seedDefaults(String userId) async {
    final now = DateTime.now();
    final categories = <CategoryModel>[];

    // Expense sub-categories
    for (final def in CategoryDefaults.expenseCategories) {
      categories.add(
        CategoryModel(
          id: _uuid.v4(),
          displayNumber: def.number,
          name: def.name,
          emoji: def.emoji,
          type: 'expense',
          parentKey: def.parentKey,
          isEnabled: true,
          sortOrder: def.number,
          createdAt: now,
        ),
      );
    }

    // Income categories
    for (final def in CategoryDefaults.incomeCategories) {
      categories.add(
        CategoryModel(
          id: _uuid.v4(),
          displayNumber: def.number,
          name: def.name,
          emoji: def.emoji,
          type: 'income',
          parentKey: 'income',
          isEnabled: true,
          sortOrder: 100 + def.number, // Income sorts after expense
          createdAt: now,
        ),
      );
    }

    // Batch insert
    final rows = categories.map((c) {
      final json = c.toJson();
      json['user_id'] = userId;
      return json;
    }).toList();

    await _client.from(AppSupabase.categoriesTable).insert(rows);
    return categories;
  }

  /// Toggle category enabled/disabled
  Future<void> toggleEnabled(String categoryId, bool enabled) async {
    await _client
        .from(AppSupabase.categoriesTable)
        .update({'is_enabled': enabled})
        .eq('id', categoryId);
  }

  /// Update category name/emoji
  Future<void> update(CategoryModel category) async {
    await _client
        .from(AppSupabase.categoriesTable)
        .update(category.toJson())
        .eq('id', category.id);
  }

  Future<CategoryModel> create({
    required String userId,
    required CategoryModel category,
  }) async {
    final json = category.toJson();
    json['user_id'] = userId;
    await _client.from(AppSupabase.categoriesTable).insert(json);
    return category;
  }

  Future<void> delete(String categoryId) async {
    try {
      await _client
          .from(AppSupabase.categoriesTable)
          .delete()
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      // FK guard: category is referenced by one or more transactions.
      if (e.code == '23503') {
        throw Exception(
          'Cannot delete category because transactions still use it. Disable it instead.',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteWithTransactionReassign({
    required String userId,
    required CategoryModel category,
  }) async {
    final fallback = await _ensureArchiveCategory(
      userId: userId,
      type: category.type,
      parentKey: category.parentKey,
    );

    if (fallback.id != category.id) {
      await _client
          .from(AppSupabase.transactionsTable)
          .update({'category_id': fallback.id})
          .eq('owner_user_id', userId)
          .eq('category_id', category.id);
    }

    try {
      await _client
          .from(AppSupabase.categoriesTable)
          .delete()
          .eq('id', category.id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Exception(
          'Category is still used by protected records. Disable it instead.',
        );
      }
      rethrow;
    }
  }

  Future<CategoryModel> _ensureArchiveCategory({
    required String userId,
    required String type,
    required String? parentKey,
  }) async {
    final archiveName = type == 'income'
        ? 'Archived Income'
        : 'Archived Expense';
    final existing = await _client
        .from(AppSupabase.categoriesTable)
        .select()
        .eq('user_id', userId)
        .eq('type', type)
        .eq('name', archiveName)
        .limit(1);
    if (existing.isNotEmpty) {
      return CategoryModel.fromJson(existing.first);
    }

    final fallback = CategoryModel(
      id: _uuid.v4(),
      displayNumber: 9999,
      name: archiveName,
      emoji: '🗂️',
      type: type,
      parentKey: parentKey,
      isEnabled: false,
      sortOrder: 999999,
      createdAt: DateTime.now(),
    );
    final json = fallback.toJson();
    json['user_id'] = userId;
    await _client.from(AppSupabase.categoriesTable).insert(json);
    return fallback;
  }
}
