import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/bill_reminder_model.dart';
import '../../data/repositories/bill_reminder_repository.dart';
import '../../domain/enums/recurrence_frequency.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

final billReminderRepositoryProvider = Provider<BillReminderRepository>(
  (ref) => BillReminderRepository(),
);

final billRemindersProvider =
    StateNotifierProvider<
      BillRemindersNotifier,
      AsyncValue<List<BillReminderModel>>
    >((ref) {
      final repo = ref.read(billReminderRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      final groupIds = ref.watch(groupIdsProvider);
      return BillRemindersNotifier(repo, userId, groupIds);
    });

class BillReminderPreview {
  final BillReminderModel reminder;
  final DateTime dueDate;
  final bool isOverdue;
  final int daysLeft;

  const BillReminderPreview({
    required this.reminder,
    required this.dueDate,
    required this.isOverdue,
    required this.daysLeft,
  });
}

final upcomingBillRemindersProvider = Provider<List<BillReminderPreview>>((
  ref,
) {
  final list = ref.watch(billRemindersProvider).valueOrNull ?? [];
  final repo = ref.watch(billReminderRepositoryProvider);
  final now = DateTime.now();

  final previews = list.where((e) => e.isActive).map((e) {
    final due = repo.nextDueDate(e, now);
    final days = due.difference(DateTime(now.year, now.month, now.day)).inDays;
    return BillReminderPreview(
      reminder: e,
      dueDate: due,
      isOverdue: days < 0,
      daysLeft: days,
    );
  }).toList();

  previews.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return previews;
});

class BillRemindersNotifier
    extends StateNotifier<AsyncValue<List<BillReminderModel>>> {
  final BillReminderRepository _repo;
  final String? _userId;
  final List<String> _groupIds;
  static const _uuid = Uuid();

  BillRemindersNotifier(this._repo, this._userId, this._groupIds)
    : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getForUser(
        userId: _userId,
        groupIds: _groupIds,
      );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReminder({
    required String title,
    double? amount,
    required String currency,
    required RecurrenceFrequency dueFrequency,
    required int intervalCount,
    required DateTime anchorDate,
    required List<int> reminderDaysBefore,
    required bool sendOverdue,
    String? recurringRuleId,
    String? groupId,
  }) async {
    if (_userId == null) return;
    final model = BillReminderModel(
      id: _uuid.v4(),
      userId: _userId,
      groupId: groupId,
      recurringRuleId: recurringRuleId,
      title: title,
      amount: amount,
      currency: currency,
      dueFrequency: dueFrequency,
      dueIntervalCount: intervalCount,
      anchorDate: anchorDate,
      reminderDaysBefore: reminderDaysBefore,
      sendOverdue: sendOverdue,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.create(model);
    await load();
  }

  Future<void> updateReminder(BillReminderModel model) async {
    await _repo.update(model.copyWithModel(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.delete(id);
    await load();
  }
}
