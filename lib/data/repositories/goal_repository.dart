import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final SupabaseClient _client = AppSupabase.client;

  Future<List<GoalModel>> getForUser(String userId) async {
    try {
      final data = await _client
          .from(AppSupabase.goalsTable)
          .select()
          .eq('user_id', userId)
          .order('sort_order', ascending: true);
      return data.map((json) => GoalModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      // Missing table in remote schema cache: keep app usable until migration is applied.
      if (e.code == 'PGRST205') return [];
      rethrow;
    }
  }

  Future<GoalModel> create(GoalModel goal) async {
    await _client.from(AppSupabase.goalsTable).insert(goal.toJson());
    return goal;
  }

  Future<void> update(GoalModel goal) async {
    await _client
        .from(AppSupabase.goalsTable)
        .update(goal.toJson())
        .eq('id', goal.id);
  }

  Future<void> delete(String id) async {
    await _client.from(AppSupabase.goalsTable).delete().eq('id', id);
  }
}
