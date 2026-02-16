import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/models/account_model.dart';
import '../../domain/enums/account_type.dart';
import '../../domain/enums/owner_scope.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<AccountModel>>>((
      ref,
    ) {
      final userId = ref.watch(currentUserIdProvider);
      final groupIds = ref.watch(groupIdsProvider);
      final groupMemberIds = ref.watch(groupMemberIdsProvider);
      final repo = ref.read(accountRepositoryProvider);
      return AccountsNotifier(repo, userId, groupIds, groupMemberIds);
    });

class AccountsNotifier extends StateNotifier<AsyncValue<List<AccountModel>>> {
  final AccountRepository _repo;
  final String? _userId;
  final List<String> _groupIds;
  final List<String> _groupMemberIds;
  static const _uuid = Uuid();

  AccountsNotifier(
    this._repo,
    this._userId,
    this._groupIds,
    this._groupMemberIds,
  ) : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final accounts = await _repo.getAllVisible(
        _userId,
        _groupIds,
        _groupMemberIds,
      );
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    OwnerScope ownerScope = OwnerScope.shared,
    String? groupId,
    String currency = 'JPY',
    double initialBalance = 0,
  }) async {
    if (_userId == null) return;
    final resolvedGroupId =
        groupId ??
        (ownerScope == OwnerScope.shared && _groupIds.isNotEmpty
            ? _groupIds.first
            : null);
    if (ownerScope == OwnerScope.shared && resolvedGroupId == null) {
      throw Exception(
        'No active group found. Connect your partner in Settings first.',
      );
    }

    final account = AccountModel(
      id: _uuid.v4(),
      name: name,
      type: type,
      ownerScope: ownerScope,
      ownerUserId: _userId,
      groupId: resolvedGroupId,
      currency: currency,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
    );

    await _repo.create(account);
    await load();
  }

  Future<void> updateAccount(AccountModel account) async {
    await _repo.update(account);
    await load();
  }

  Future<void> deleteAccount(String id) async {
    await _repo.delete(id);
    await load();
  }
}
