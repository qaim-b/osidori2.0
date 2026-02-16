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
        .order('created_at');
    return data.map((json) => AccountModel.fromJson(json)).toList();
  }

  /// All accounts visible to a user (their own + shared group ones)
  Future<List<AccountModel>> getAllVisible(
    String userId,
    List<String> groupIds,
    List<String> groupMemberIds,
  ) async {
    final personal = await getForUser(userId);
    if (groupIds.isEmpty && groupMemberIds.isEmpty) return personal;

    final all = <AccountModel>[...personal];

    if (groupIds.isNotEmpty) {
      final sharedData = await _client
          .from(AppSupabase.accountsTable)
          .select()
          .inFilter('group_id', groupIds)
          .order('created_at');
      all.addAll(sharedData.map((json) => AccountModel.fromJson(json)));
    }

    final partnerIds = groupMemberIds.where((id) => id != userId).toList();
    if (partnerIds.isNotEmpty) {
      final partnerData = await _client
          .from(AppSupabase.accountsTable)
          .select()
          .inFilter('owner_user_id', partnerIds)
          .order('created_at');
      all.addAll(partnerData.map((json) => AccountModel.fromJson(json)));
    }

    final dedup = <String, AccountModel>{for (final a in all) a.id: a};
    return dedup.values.toList();
  }

  Future<void> update(AccountModel account) async {
    await _client
        .from(AppSupabase.accountsTable)
        .update(account.toJson())
        .eq('id', account.id);
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(AppSupabase.accountsTable).delete().eq('id', id);
    } on PostgrestException catch (e) {
      // FK guard: account is referenced by one or more transactions.
      if (e.code == '23503') {
        throw Exception(
          'Cannot delete account because transactions still use it.',
        );
      }
      rethrow;
    }
  }

  Future<AccountModel?> getById(String id) async {
    final rows = await _client
        .from(AppSupabase.accountsTable)
        .select()
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) return null;
    return AccountModel.fromJson(rows.first);
  }

  /// Repairs legacy rows where "shared" accounts were saved with null group_id.
  Future<int> assignUngroupedSharedToGroup({
    required String userId,
    required String groupId,
  }) async {
    final updated = await _client
        .from(AppSupabase.accountsTable)
        .update({'group_id': groupId})
        .eq('owner_user_id', userId)
        .eq('owner_scope', 'shared')
        .isFilter('group_id', null)
        .select('id');
    return updated.length;
  }
}
