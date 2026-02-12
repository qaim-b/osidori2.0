import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/group_repository.dart';
import 'auth_provider.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

final groupsProvider =
    StateNotifierProvider<GroupNotifier, AsyncValue<List<GroupModel>>>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      final repo = ref.read(groupRepositoryProvider);
      return GroupNotifier(repo, userId);
    });

final activeGroupIdStateProvider = StateProvider<String?>((ref) => null);

final groupIdsProvider = Provider<List<String>>((ref) {
  final groups = ref.watch(groupsProvider).valueOrNull ?? [];
  return groups.map((g) => g.id).toList();
});

final groupMemberIdsProvider = Provider<List<String>>((ref) {
  final groups = ref.watch(groupsProvider).valueOrNull ?? [];
  final seen = <String>{};
  for (final g in groups) {
    seen.addAll(g.memberIds);
  }
  return seen.toList();
});

final activeGroupIdProvider = Provider<String?>((ref) {
  final groups = ref.watch(groupsProvider).valueOrNull ?? [];
  final selected = ref.watch(activeGroupIdStateProvider);
  if (selected != null && groups.any((g) => g.id == selected)) {
    return selected;
  }
  return groups.isEmpty ? null : groups.first.id;
});

final activeGroupMemberProfilesProvider = FutureProvider<List<UserModel>>((
  ref,
) async {
  final groups = ref.watch(groupsProvider).valueOrNull ?? [];
  if (groups.isEmpty) return [];
  final activeGroupId = ref.watch(activeGroupIdProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  GroupModel group;
  if (activeGroupId != null && groups.any((g) => g.id == activeGroupId)) {
    group = groups.firstWhere((g) => g.id == activeGroupId);
  } else {
    group = groups.first;
  }
  final repo = ref.read(authRepositoryProvider);
  final profiles = await Future.wait(
    group.memberIds.map((id) => repo.getProfile(id)),
  );
  profiles.sort((a, b) {
    if (a.id == currentUserId) return -1;
    if (b.id == currentUserId) return 1;
    return a.name.compareTo(b.name);
  });
  return profiles;
});

class GroupNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final GroupRepository _repo;
  final String? _userId;
  static const _uuid = Uuid();

  GroupNotifier(this._repo, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      load();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final groups = await _repo.getGroupsForUser(_userId);
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> createCoupleGroup({
    required String partnerUserId,
    String? name,
  }) async {
    if (_userId == null) {
      throw Exception('You must be logged in to create/connect a group');
    }

    // Normalize copy/paste input from chat/apps:
    // remove spaces/newlines/quotes while keeping hyphens.
    final trimmedPartner = partnerUserId
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(RegExp(r'\s+'), '');

    if (trimmedPartner.isEmpty || trimmedPartner == _userId) {
      return null;
    }
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
    );
    if (!uuidPattern.hasMatch(trimmedPartner)) {
      throw Exception(
        'Partner code is invalid. Paste the full user ID (UUID) exactly.',
      );
    }

    final currentGroups = state.valueOrNull ?? [];
    final alreadyLinked = currentGroups.any(
      (g) => g.memberIds.contains(trimmedPartner),
    );
    if (alreadyLinked) {
      return currentGroups
          .firstWhere((g) => g.memberIds.contains(trimmedPartner))
          .id;
    }

    final groupId = _uuid.v4();
    await _repo.createGroup(
      id: groupId,
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Our Shared Space',
      createdByUserId: _userId,
      memberIds: [_userId, trimmedPartner],
    );
    await load();
    return groupId;
  }
}
