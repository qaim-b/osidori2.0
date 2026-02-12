import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/account_model.dart';

/// CRUD for manual financial accounts.
class AccountRepository {
  final SupabaseClient _client = AppSupabase.client;

  Future<AccountModel> create(AccountModel account) async {
    await _client.from(AppSupabase.accountsTable).insert(account.toJson());
    return account;
  }

  Future<List<AccountModel>> getForUser(String userId) async {
    final data = await _client
        .from(AppSupabase.accountsTable)
        .select()
        .eq('owner_user_id', userId)
        .order('created_at');
    return data.map((json) => AccountModel.fromJson(json)).toList();
  }

  /// Get shared accounts for a group
  Future<List<AccountModel>> getForGroup(String groupId) async {
    final data = await _client
        .from(AppSupabase.accountsTable)
        .select()
        .eq('group_id', groupId)
        .eq('owner_scope', 'shared')
        .order('created_at');
    return data.map((json) => AccountModel.fromJson(json)).toList();
  }

  /// All accounts visible to a user (their own + shared group ones)
  Future<List<AccountModel>> getAllVisible(
      String userId, String? groupId) async {
    final personal = await getForUser(userId);
    if (groupId == null) return personal;

    final shared = await getForGroup(groupId);
    return [...personal, ...shared];
  }

  Future<void> update(AccountModel account) async {
    await _client
        .from(AppSupabase.accountsTable)
        .update(account.toJson())
        .eq('id', account.id);
  }

  Future<void> delete(String id) async {
    await _client.from(AppSupabase.accountsTable).delete().eq('id', id);
  }
}
