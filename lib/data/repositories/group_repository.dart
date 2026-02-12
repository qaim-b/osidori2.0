import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/group_model.dart';

/// Manages couple/group creation and membership.
class GroupRepository {
  final SupabaseClient _client = AppSupabase.client;

  /// Create a new group (couple)
  Future<GroupModel> createGroup({
    required String id,
    required String name,
    required String createdByUserId,
    required List<String> memberIds,
  }) async {
    final group = GroupModel(
      id: id,
      name: name,
      memberIds: memberIds,
      createdByUserId: createdByUserId,
      createdAt: DateTime.now(),
    );

    await _client.from(AppSupabase.groupsTable).insert(group.toJson());

    // Insert each member into the junction table
    for (final memberId in memberIds) {
      await _client.from(AppSupabase.groupMembersTable).insert({
        'group_id': id,
        'user_id': memberId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    }

    return group;
  }

  /// Fetch all groups a user belongs to
  Future<List<GroupModel>> getGroupsForUser(String userId) async {
    final memberRows = await _client
        .from(AppSupabase.groupMembersTable)
        .select('group_id')
        .eq('user_id', userId);

    if (memberRows.isEmpty) return [];

    final groupIds =
        memberRows.map((r) => r['group_id'] as String).toList();

    final data = await _client
        .from(AppSupabase.groupsTable)
        .select()
        .inFilter('id', groupIds);

    return data.map((json) => GroupModel.fromJson(json)).toList();
  }

  /// Add a member to a group (invite accepted)
  Future<void> addMember(String groupId, String userId) async {
    // Update the group's member_ids array
    final groupData = await _client
        .from(AppSupabase.groupsTable)
        .select()
        .eq('id', groupId)
        .single();

    final group = GroupModel.fromJson(groupData);
    final updatedIds = [...group.memberIds, userId];

    await _client.from(AppSupabase.groupsTable).update(
      {'member_ids': updatedIds},
    ).eq('id', groupId);

    await _client.from(AppSupabase.groupMembersTable).insert({
      'group_id': groupId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get a single group by ID
  Future<GroupModel> getGroup(String groupId) async {
    final data = await _client
        .from(AppSupabase.groupsTable)
        .select()
        .eq('id', groupId)
        .single();
    return GroupModel.fromJson(data);
  }
}
