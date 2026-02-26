import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../data/models/bill_reminder_model.dart';
import '../../../data/models/recurring_rule_model.dart';
import '../../../domain/enums/recurrence_frequency.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/enums/visibility_type.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_reminder_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/recurring_rule_provider.dart';

class AutomationScreen extends ConsumerStatefulWidget {
  const AutomationScreen({super.key});

  @override
  ConsumerState<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends ConsumerState<AutomationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(() async {
      await ref.read(recurringRulesProvider.notifier).load();
      await ref.read(billRemindersProvider.notifier).load();
      await ref.read(recurringRulesProvider.notifier).generateCatchUp();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recurring = ref.watch(recurringRulesProvider);
    final reminders = ref.watch(billRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Recurring'),
            Tab(text: 'Bills'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RecurringTab(rules: recurring),
          _BillsTab(reminders: reminders),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabs.index == 0) {
            _showRecurringForm(context);
          } else {
            _showBillForm(context);
          }
        },
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          _tabs.index == 0 ? 'New Recurring Rule' : 'New Bill Reminder',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    );
  }

  Future<void> _showRecurringForm(
    BuildContext context, {
    RecurringRuleModel? edit,
  }) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final activeGroup = ref.read(activeGroupIdProvider);
    final currency = ref.read(currentCurrencyProvider);

    if (categories.isEmpty || accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create categories and accounts first.'),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    final amountCtrl = TextEditingController(
      text: edit == null ? '' : edit.amount.toStringAsFixed(0),
    );
    final intervalCtrl = TextEditingController(
      text: (edit?.intervalCount ?? 1).toString(),
    );
    final noteCtrl = TextEditingController(text: edit?.note ?? '');

    TransactionType type = edit?.type ?? TransactionType.expense;
    RecurrenceFrequency freq = edit?.frequency ?? RecurrenceFrequency.monthly;
    VisibilityType visibility = edit?.visibility ?? VisibilityType.shared;
    DateTime startDate = edit?.startDate ?? DateTime.now();
    DateTime? endDate = edit?.endDate;
    String categoryId = edit?.categoryId ?? categories.first.id;
    String fromAccountId = edit?.fromAccountId ?? accounts.first.id;
    String? toAccountId = edit?.toAccountId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            final filteredCategories = categories
                .where(
                  (c) => type == TransactionType.expense
                      ? c.isExpense
                      : type == TransactionType.income
                      ? c.isIncome
                      : true,
                )
                .toList();
            if (!filteredCategories.any((c) => c.id == categoryId)) {
              categoryId = filteredCategories.isNotEmpty
                  ? filteredCategories.first.id
                  : categories.first.id;
            }

            return AlertDialog(
              title: Text(
                edit == null ? 'New Recurring Rule' : 'Edit Recurring Rule',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TransactionType>(
                            initialValue: type,
                            items: TransactionType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDialog(() => type = v);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount ($currency)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      items: filteredCategories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.emoji} ${c.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialog(() => categoryId = v);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: fromAccountId,
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialog(() => fromAccountId = v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'From Account',
                      ),
                    ),
                    if (type == TransactionType.transfer) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: toAccountId,
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setDialog(() => toAccountId = v),
                        decoration: const InputDecoration(
                          labelText: 'To Account',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<RecurrenceFrequency>(
                            initialValue: freq,
                            items: const [
                              DropdownMenuItem(
                                value: RecurrenceFrequency.monthly,
                                child: Text('Monthly'),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.yearly,
                                child: Text('Yearly'),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.weekly,
                                child: Text('Weekly'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setDialog(() => freq = v);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: intervalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Every X',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<VisibilityType>(
                      initialValue: visibility,
                      items: VisibilityType.values
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text(v.name)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialog(() => visibility = v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Start: ${startDate.monthDayYear}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialog(() => startDate = picked);
                          }
                        },
                        child: const Text('Pick'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endDate == null
                            ? 'End: Never'
                            : 'End: ${endDate!.monthDayYear}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endDate ?? startDate,
                                firstDate: startDate,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialog(() => endDate = picked);
                              }
                            },
                            child: const Text('Pick'),
                          ),
                          if (endDate != null)
                            TextButton(
                              onPressed: () => setDialog(() => endDate = null),
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final amount = double.tryParse(amountCtrl.text.trim());
    final interval = int.tryParse(intervalCtrl.text.trim()) ?? 1;
    if (nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill valid name and amount.')),
      );
      return;
    }

    if (edit == null) {
      await ref
          .read(recurringRulesProvider.notifier)
          .addRule(
            name: nameCtrl.text.trim(),
            type: type,
            amount: amount,
            currency: currency,
            categoryId: categoryId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            visibility: visibility,
            frequency: freq,
            intervalCount: interval,
            startDate: startDate,
            endDate: endDate,
            groupId: activeGroup,
          );
    } else {
      await ref
          .read(recurringRulesProvider.notifier)
          .updateRule(
            edit.copyWithModel(
              name: nameCtrl.text.trim(),
              type: type,
              amount: amount,
              currency: currency,
              categoryId: categoryId,
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              visibility: visibility,
              frequency: freq,
              intervalCount: interval,
              startDate: startDate,
              endDate: endDate,
              groupId: visibility == VisibilityType.shared ? activeGroup : null,
            ),
          );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          edit == null ? 'Recurring rule created' : 'Recurring rule updated',
        ),
      ),
    );
  }

  Future<void> _showBillForm(
    BuildContext context, {
    BillReminderModel? edit,
  }) async {
    final activeGroup = ref.read(activeGroupIdProvider);
    final currency = ref.read(currentCurrencyProvider);
    final titleCtrl = TextEditingController(text: edit?.title ?? '');
    final amountCtrl = TextEditingController(
      text: edit?.amount == null ? '' : edit!.amount!.toStringAsFixed(0),
    );
    final intervalCtrl = TextEditingController(
      text: (edit?.dueIntervalCount ?? 1).toString(),
    );
    final reminderCtrl = TextEditingController(
      text: (edit?.reminderDaysBefore ?? const [7, 2, 0]).join(','),
    );

    RecurrenceFrequency freq =
        edit?.dueFrequency ?? RecurrenceFrequency.monthly;
    DateTime anchorDate = edit?.anchorDate ?? DateTime.now();
    bool overdue = edit?.sendOverdue ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return AlertDialog(
            title: Text(
              edit == null ? 'New Bill Reminder' : 'Edit Bill Reminder',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount ($currency, optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<RecurrenceFrequency>(
                          initialValue: freq,
                          items: const [
                            DropdownMenuItem(
                              value: RecurrenceFrequency.monthly,
                              child: Text('Monthly'),
                            ),
                            DropdownMenuItem(
                              value: RecurrenceFrequency.yearly,
                              child: Text('Yearly'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialog(() => freq = v);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Due Frequency',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: intervalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Every X',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Anchor: ${anchorDate.monthDayYear}'),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: anchorDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialog(() => anchorDate = picked);
                        }
                      },
                      child: const Text('Pick'),
                    ),
                  ),
                  TextField(
                    controller: reminderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reminder days before (comma separated)',
                      helperText: 'Default: 7,2,0',
                    ),
                  ),
                  SwitchListTile(
                    value: overdue,
                    onChanged: (v) => setDialog(() => overdue = v),
                    title: const Text('Send overdue reminders'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final amount = amountCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(amountCtrl.text.trim());
    final interval = int.tryParse(intervalCtrl.text.trim()) ?? 1;
    final reminderDays =
        reminderCtrl.text
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>()
            .where((d) => d >= 0)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (titleCtrl.text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }

    if (edit == null) {
      await ref
          .read(billRemindersProvider.notifier)
          .addReminder(
            title: titleCtrl.text.trim(),
            amount: amount,
            currency: currency,
            dueFrequency: freq,
            intervalCount: interval,
            anchorDate: anchorDate,
            reminderDaysBefore: reminderDays.isEmpty
                ? const [7, 2, 0]
                : reminderDays,
            sendOverdue: overdue,
            groupId: activeGroup,
          );
    } else {
      await ref
          .read(billRemindersProvider.notifier)
          .updateReminder(
            edit.copyWithModel(
              title: titleCtrl.text.trim(),
              amount: amount,
              dueFrequency: freq,
              dueIntervalCount: interval,
              anchorDate: anchorDate,
              reminderDaysBefore: reminderDays.isEmpty
                  ? const [7, 2, 0]
                  : reminderDays,
              sendOverdue: overdue,
              groupId: activeGroup,
            ),
          );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          edit == null ? 'Bill reminder created' : 'Bill reminder updated',
        ),
      ),
    );
  }
}

class _RecurringTab extends ConsumerWidget {
  final AsyncValue<List<RecurringRuleModel>> rules;

  const _RecurringTab({required this.rules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return rules.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No recurring rules yet. Tap + to create one.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemBuilder: (context, index) {
            final r = items[index];
            return Card(
              child: ListTile(
                title: Text(r.name),
                subtitle: Text(
                  '${r.type.name} • ${r.amount.toStringAsFixed(0)} ${r.currency}\n${r.frequency.name} every ${r.intervalCount} • starts ${r.startDate.monthDayYear}',
                  style: const TextStyle(fontSize: 12.5),
                ),
                isThreeLine: true,
                trailing: Switch(
                  value: r.isActive,
                  onChanged: (v) => ref
                      .read(recurringRulesProvider.notifier)
                      .updateRule(r.copyWithModel(isActive: v)),
                ),
                onTap: () async {
                  await (context
                          .findAncestorStateOfType<_AutomationScreenState>())
                      ?._showRecurringForm(context, edit: r);
                },
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete rule?'),
                      content: const Text(
                        'This removes future auto-generation for this series.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref
                        .read(recurringRulesProvider.notifier)
                        .deleteRule(r.id);
                  }
                },
              ),
            );
          },
          separatorBuilder: (_, index) => const SizedBox(height: 6),
          itemCount: items.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _BillsTab extends ConsumerWidget {
  final AsyncValue<List<BillReminderModel>> reminders;

  const _BillsTab({required this.reminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingBillRemindersProvider);
    return reminders.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No bill reminders yet. Tap + to create one.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...upcoming
                        .take(5)
                        .map(
                          (u) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              '${u.reminder.title}: ${u.dueDate.monthDayYear} ${u.daysLeft >= 0 ? '(in ${u.daysLeft}d)' : '(overdue)'}',
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((r) {
              return Card(
                child: ListTile(
                  title: Text(r.title),
                  subtitle: Text(
                    '${r.dueFrequency.name} every ${r.dueIntervalCount} • anchor ${r.anchorDate.monthDayYear}\nreminders: ${r.reminderDaysBefore.join(',')} days before',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  isThreeLine: true,
                  trailing: Switch(
                    value: r.isActive,
                    onChanged: (v) => ref
                        .read(billRemindersProvider.notifier)
                        .updateReminder(r.copyWithModel(isActive: v)),
                  ),
                  onTap: () async {
                    await (context
                            .findAncestorStateOfType<_AutomationScreenState>())
                        ?._showBillForm(context, edit: r);
                  },
                  onLongPress: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete reminder?'),
                        content: const Text(
                          'This deletes the reminder series.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref
                          .read(billRemindersProvider.notifier)
                          .deleteReminder(r.id);
                    }
                  },
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
