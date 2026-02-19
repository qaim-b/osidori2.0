import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/common/editorial.dart';
import '../../widgets/common/themed_backdrop.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(monthlyTransactionsProvider.notifier).load(),
      ref.read(categoriesProvider.notifier).load(),
      ref.read(budgetLimitsProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final roleColors = ref.watch(roleColorsProvider);
    final budgetLimitMap = ref.watch(budgetLimitMapProvider);

    final catEntityMap = <String, CategoryEntity>{};
    final catNameMap = <String, String>{};
    final resolvedCategoryNameMap = <String, String>{};
    final resolvedCategoryEmojiMap = <String, String>{};
    final catSnapshotNameMap = <String, String>{};
    final catSnapshotEmojiMap = <String, String>{};
    for (final cat in categories.valueOrNull ?? <CategoryEntity>[]) {
      catEntityMap[cat.id] = cat;
      catNameMap[cat.id] = cat.shortLabel;
      resolvedCategoryNameMap[cat.id] = cat.name;
      resolvedCategoryEmojiMap[cat.id] = cat.emoji;
    }
    for (final txn in txns) {
      if (txn.categoryNameSnapshot != null) {
        catSnapshotNameMap[txn.categoryId] = txn.categoryNameSnapshot!;
        resolvedCategoryNameMap[txn.categoryId] =
            resolvedCategoryNameMap[txn.categoryId] ??
            txn.categoryNameSnapshot!;
      }
      if (txn.categoryEmojiSnapshot != null) {
        catSnapshotEmojiMap[txn.categoryId] = txn.categoryEmojiSnapshot!;
        resolvedCategoryEmojiMap[txn.categoryId] =
            resolvedCategoryEmojiMap[txn.categoryId] ??
            txn.categoryEmojiSnapshot!;
      }
      resolvedCategoryNameMap[txn.categoryId] =
          resolvedCategoryNameMap[txn.categoryId] ??
          (txn.categoryDisplayNumberSnapshot != null
              ? 'Category #${txn.categoryDisplayNumberSnapshot}'
              : 'Category');
      resolvedCategoryEmojiMap[txn.categoryId] =
          resolvedCategoryEmojiMap[txn.categoryId] ?? '🧾';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemedBackdrop(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        ref
                            .read(selectedMonthProvider.notifier)
                            .state = DateTime(
                          selectedMonth.year,
                          selectedMonth.month - 1,
                          1,
                        );
                      },
                    ),
                    Text(
                      selectedMonth.monthYear,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        ref
                            .read(selectedMonthProvider.notifier)
                            .state = DateTime(
                          selectedMonth.year,
                          selectedMonth.month + 1,
                          1,
                        );
                      },
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              color: AppColors.income,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Income',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              CurrencyFormatter.format(
                                (totals['income'] ?? 0.0).toDouble(),
                              ),
                              style: const TextStyle(
                                color: AppColors.income,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: roleColors.gradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Spending',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DisplayNumber(
                              value: CurrencyFormatter.format(
                                (totals['expense'] ?? 0.0).toDouble(),
                              ),
                              size: 34,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: EditorialCard(
                  margin: const EdgeInsets.all(16),
                  accentTop: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Breakdown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final total = categoryTotals.values.fold<double>(
                            0,
                            (sum, v) => sum + v,
                          );
                          if (total == 0) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No expenses this month'),
                              ),
                            );
                          }
                          return CategoryDonutChart(
                            categoryTotals: categoryTotals,
                            categoryNames: {
                              for (final e in categoryTotals.entries)
                                e.key:
                                    resolvedCategoryNameMap[e.key] ??
                                    catNameMap[e.key] ??
                                    'Category',
                            },
                            currency: 'JPY',
                            totalAmount: total,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SectionLabel(text: 'By Category')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'By Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/budget/planner'),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('All Budgets'),
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final total = categoryTotals.values.fold<double>(
                    0,
                    (sum, v) => sum + v,
                  );
                  final sorted = categoryTotals.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  if (sorted.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No data yet')),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = sorted[index];
                      final cat = catEntityMap[entry.key];
                      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
                      final budgetLimit = budgetLimitMap[entry.key];
                      final limitProgress =
                          budgetLimit != null && budgetLimit > 0
                          ? (entry.value / budgetLimit).clamp(0.0, 1.5)
                          : null;

                      return EditorialCard(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              context.push('/budget/category/${entry.key}'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.surfaceVariant,
                                      child: Text(
                                        cat?.emoji ??
                                            resolvedCategoryEmojiMap[entry
                                                .key] ??
                                            catSnapshotEmojiMap[entry.key] ??
                                            '🧾',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cat?.name ??
                                            resolvedCategoryNameMap[entry
                                                .key] ??
                                            catSnapshotNameMap[entry.key] ??
                                            'Category',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(entry.value)}  ${pct.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textHint,
                                    ),
                                  ],
                                ),
                                if (budgetLimit != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 6,
                                      value: limitProgress == null
                                          ? 0
                                          : limitProgress.clamp(0.0, 1.0),
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        (limitProgress ?? 0) <= 1
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Budget ${CurrencyFormatter.format(budgetLimit)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: sorted.length > 8 ? 8 : sorted.length),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}
