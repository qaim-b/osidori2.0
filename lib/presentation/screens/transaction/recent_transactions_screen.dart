import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/themed_backdrop.dart';
import '../../widgets/transaction/transaction_tile.dart';

class RecentTransactionsScreen extends ConsumerStatefulWidget {
  const RecentTransactionsScreen({super.key});

  @override
  ConsumerState<RecentTransactionsScreen> createState() =>
      _RecentTransactionsScreenState();
}

class _RecentTransactionsScreenState
    extends ConsumerState<RecentTransactionsScreen> {
  String? _categoryFilterId;
  String? _accountFilterId;

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    final catEntityMap = <String, CategoryEntity>{
      for (final c in categories) c.id: c,
    };
    final catOptions = txns.map((t) => t.categoryId).toSet().toList()
      ..sort((a, b) {
        final an =
            catEntityMap[a]?.name ??
            txns
                .where(
                  (t) => t.categoryId == a && t.categoryNameSnapshot != null,
                )
                .map((t) => t.categoryNameSnapshot!)
                .firstOrNull ??
            'Category';
        final bn =
            catEntityMap[b]?.name ??
            txns
                .where(
                  (t) => t.categoryId == b && t.categoryNameSnapshot != null,
                )
                .map((t) => t.categoryNameSnapshot!)
                .firstOrNull ??
            'Category';
        return an.compareTo(bn);
      });
    final accountMap = {for (final a in accounts) a.id: a.name};

    var filtered = txns;
    if (_categoryFilterId != null) {
      filtered = filtered
          .where((t) => t.categoryId == _categoryFilterId)
          .toList();
    }
    if (_accountFilterId != null) {
      filtered = filtered
          .where((t) => t.fromAccountId == _accountFilterId)
          .toList();
    }

    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('All Transactions')),
      body: ThemedBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _categoryFilterId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categories',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...catOptions.map((id) {
                          final name =
                              catEntityMap[id]?.name ??
                              txns
                                  .where(
                                    (t) =>
                                        t.categoryId == id &&
                                        t.categoryNameSnapshot != null,
                                  )
                                  .map((t) => t.categoryNameSnapshot!)
                                  .firstOrNull ??
                              'Category';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _categoryFilterId = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _accountFilterId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Bank',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Banks'),
                        ),
                        ...accountMap.entries.map((entry) {
                          return DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _accountFilterId = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: dayKeys.isEmpty
                  ? const Center(child: Text('No transactions in this month'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: dayKeys.length,
                      itemBuilder: (context, index) {
                        final dayKey = dayKeys[index];
                        final dayTxns = grouped[dayKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                              child: Text(
                                DateFormat(
                                  'd MMMM yyyy',
                                ).format(DateTime.parse(dayKey)),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ...dayTxns.map((txn) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                child: TransactionTile(
                                  transaction: txn,
                                  category: catEntityMap[txn.categoryId],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
