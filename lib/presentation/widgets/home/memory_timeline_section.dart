import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class MemoryTimelineSection extends ConsumerWidget {
  const MemoryTimelineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? <CategoryEntity>[];
    final catMap = <String, CategoryEntity>{for (final c in categories) c.id: c};

    return transactionsAsync.when(
      data: (txns) {
        final memories =
            txns.where((t) => (t.note ?? '').trim().isNotEmpty).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        final display = memories.take(5).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Memory Timeline',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                if (display.isEmpty)
                  const Text('No memories yet. Add notes to your transactions.')
                else
                  ...display.map((txn) {
                    final cat = catMap[txn.categoryId];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat?.emoji ?? '📝'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'On ${txn.date.shortDate} - ${txn.note}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(txn.amount),
                                  style: TextStyle(
                                    color: txn.isExpense
                                        ? AppColors.expense
                                        : AppColors.income,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
