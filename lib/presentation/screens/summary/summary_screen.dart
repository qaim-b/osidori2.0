import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/themed_backdrop.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(monthlyTransactionsProvider.notifier).load(),
      ref.read(categoriesProvider.notifier).load(),
      ref.read(goalsProvider.notifier).load(),
      ref.read(budgetLimitsProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals = ref.watch(monthlyTotalsProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final budgetLimits = ref.watch(budgetLimitMapProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? <CategoryEntity>[];
    final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
    final selectedMonth = ref.watch(selectedMonthProvider);
    final preset = ref.watch(activeThemePresetDataProvider);

    final catMap = <String, CategoryEntity>{
      for (final c in categories) c.id: c,
    };
    final catSnapshotNameMap = <String, String>{};
    final catSnapshotEmojiMap = <String, String>{};
    for (final t in txns) {
      if (t.categoryNameSnapshot != null) {
        catSnapshotNameMap[t.categoryId] = t.categoryNameSnapshot!;
      }
      if (t.categoryEmojiSnapshot != null) {
        catSnapshotEmojiMap[t.categoryId] = t.categoryEmojiSnapshot!;
      }
    }
    final expense = (totals['expense'] ?? 0.0).toDouble();
    final income = (totals['income'] ?? 0.0).toDouble();

    final top3 = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Sliced = top3.take(3).toList();

    final dailyAverage =
        txns.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount) /
        (DateTime.now().day.clamp(1, 31));

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
                floating: true,
                snap: true,
                title: const Text('Summary'),
                actions: [
                  IconButton(
                    tooltip: 'Set Budgets',
                    onPressed: () => context.push('/summary/set-budget'),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [preset.primary, preset.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: preset.primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Snapshot',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricPill(
                                label: 'Income',
                                value: CurrencyFormatter.format(income),
                                icon: Icons.arrow_upward_rounded,
                                color: preset.background,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricPill(
                                label: 'Expense',
                                value: CurrencyFormatter.format(expense),
                                icon: Icons.arrow_downward_rounded,
                                color: preset.background,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Text(
                    'Budget vs Actual',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: budgetLimits.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'No budget limits yet. Tap the top-right sliders icon to add them.',
                            ),
                          )
                        : Column(
                            children: budgetLimits.entries.map((entry) {
                              final cat = catMap[entry.key];
                              final actual = categoryTotals[entry.key] ?? 0;
                              final limit = entry.value;
                              final ratio = limit <= 0 ? 0.0 : (actual / limit);
                              final over = ratio > 1;
                              final barColor = over
                                  ? AppColors.expense
                                  : preset.primary;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          cat?.emoji ??
                                              catSnapshotEmojiMap[entry.key] ??
                                              '📋',
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            cat?.name ??
                                                catSnapshotNameMap[entry.key] ??
                                                'Unknown',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${CurrencyFormatter.format(actual)} / ${CurrencyFormatter.format(limit)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        minHeight: 7,
                                        value: ratio.clamp(0.0, 1.0),
                                        backgroundColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              barColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Text(
                    'Top Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: top3Sliced.isEmpty
                        ? const Text('No spending yet this month.')
                        : Column(
                            children: top3Sliced.map((entry) {
                              final cat = catMap[entry.key];
                              final pct = expense <= 0
                                  ? 0
                                  : (entry.value / expense * 100);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      cat?.emoji ??
                                          catSnapshotEmojiMap[entry.key] ??
                                          '📋',
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat?.name ??
                                            catSnapshotNameMap[entry.key] ??
                                            'Unknown',
                                      ),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(entry.value)} (${pct.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Text(
                    'Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InsightChip(
                          icon: Icons.calendar_today_rounded,
                          text:
                              'Daily avg: ${CurrencyFormatter.format(dailyAverage)}',
                        ),
                        _InsightChip(
                          icon: Icons.category_rounded,
                          text: 'Categories spent: ${categoryTotals.length}',
                        ),
                        _InsightChip(
                          icon: Icons.receipt_long_rounded,
                          text: 'Transactions: ${txns.length}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Text(
                    'Exports',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.table_chart_rounded),
                          title: const Text('Export Planning Summary XLSX'),
                          subtitle: const Text(
                            'Category totals + Budget + Exp-Bud for easy copy/paste',
                          ),
                          onTap: () async {
                            final catNameMap = <String, String>{
                              for (final c in categories.where(
                                (c) => c.isExpense,
                              ))
                                c.id: c.shortLabel,
                            };
                            final path =
                                await CsvExporter.exportExpenseCategoryMatrixXlsx(
                                  transactions: txns,
                                  categoryNames: catNameMap,
                                  year: selectedMonth.year,
                                  month: selectedMonth.month,
                                  budgetLimits: budgetLimits,
                                );
                            await CsvExporter.shareFile(path);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Planning summary XLSX exported'),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.download_rounded),
                          title: const Text(
                            'Export Standard Transactions XLSX',
                          ),
                          subtitle: const Text('General transaction export'),
                          onTap: () async {
                            final catNameMap = <String, String>{
                              for (final c in categories) c.id: c.shortLabel,
                            };
                            final path =
                                await CsvExporter.exportTransactionsXlsx(
                                  transactions: txns,
                                  categoryNames: catNameMap,
                                  year: selectedMonth.year,
                                  month: selectedMonth.month,
                                );
                            await CsvExporter.shareFile(path);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transactions XLSX exported'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InsightChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
