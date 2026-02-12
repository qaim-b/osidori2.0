import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/budget_limit_model.dart';

class BudgetLimitRepository {
  final SupabaseClient _client = AppSupabase.client;

  Future<List<BudgetLimitModel>> getForUser(String userId) async {
    try {
      final data = await _client
          .from(AppSupabase.budgetLimitsTable)
          .select()
          .eq('user_id', userId);
      return data.map((json) => BudgetLimitModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') return [];
      rethrow;
    }
  }

  /// Upsert a budget limit — inserts or updates based on user_id + category_id
  Future<void> upsert(BudgetLimitModel limit) async {
    await _client
        .from(AppSupabase.budgetLimitsTable)
        .upsert(limit.toJson(), onConflict: 'user_id,category_id');
  }

  Future<void> delete(String id) async {
    await _client
        .from(AppSupabase.budgetLimitsTable)
        .delete()
        .eq('id', id);
  }
}
