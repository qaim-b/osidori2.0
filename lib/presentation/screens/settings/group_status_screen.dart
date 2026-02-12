import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transaction_provider.dart';

class GroupStatusScreen extends ConsumerWidget {
  const GroupStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final activeGroupId = ref.watch(activeGroupIdProvider);
    final userId = ref.watch(currentUserIdProvider);
    final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];

    final shared = txns.where((t) => t.isShared).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final partnerCount = shared.where((t) => t.ownerUserId != userId).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Group Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: groups.when(
              data: (list) {
                if (list.isEmpty) {
                  return const ListTile(
                    title: Text('No group connected'),
                    subtitle: Text(
                      'Go to Group Management to connect your partner.',
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Group',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: list
                            .map(
                              (g) => ChoiceChip(
                                label: Text('${g.name} (${g.memberCount})'),
                                selected:
                                    g.id == (activeGroupId ?? list.first.id),
                                onSelected: (_) {
                                  ref
                                      .read(activeGroupIdStateProvider.notifier)
                                      .state = g
                                      .id;
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ListTile(title: Text('Error: $e')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      label: 'Shared Txns',
                      value: '${shared.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CountCard(
                      label: 'Partner Txns',
                      value: '$partnerCount',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_circle_outlined),
              title: const Text('Repair legacy shared records'),
              subtitle: const Text('Attach old shared rows to active group id'),
              trailing: FilledButton(
                onPressed: activeGroupId == null
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          if (userId == null) return;
                          final groupId = ref.read(activeGroupIdProvider);
                          if (groupId == null) return;
                          final txnCount = await ref
                              .read(transactionRepositoryProvider)
                              .assignUngroupedSharedToGroup(
                                userId: userId,
                                groupId: groupId,
                              );
                          final accCount = await ref
                              .read(accountRepositoryProvider)
                              .assignUngroupedSharedToGroup(
                                userId: userId,
                                groupId: groupId,
                              );
                          await ref
                              .read(monthlyTransactionsProvider.notifier)
                              .load();
                          await ref.read(accountsProvider.notifier).load();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Updated: $txnCount transactions, $accCount accounts',
                              ),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Repair failed: $e')),
                          );
                        }
                      },
                child: const Text('Run'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(child: _RecentSharedList(shared: shared)),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final String value;

  const _CountCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _RecentSharedList extends StatelessWidget {
  final List<TransactionModel> shared;

  const _RecentSharedList({required this.shared});

  @override
  Widget build(BuildContext context) {
    if (shared.isEmpty) {
      return const ListTile(title: Text('No shared activity this month'));
    }
    return Column(
      children: shared.take(12).map((t) {
        final sign = t.isExpense ? '-' : '+';
        return ListTile(
          dense: true,
          leading: Icon(t.isExpense ? Icons.south_west : Icons.north_east),
          title: Text(t.categoryNameSnapshot ?? 'Transaction'),
          subtitle: Text(t.note?.isNotEmpty == true ? t.note! : 'No note'),
          trailing: Text('$sign${t.amount.toStringAsFixed(0)}'),
        );
      }).toList(),
    );
  }
}
