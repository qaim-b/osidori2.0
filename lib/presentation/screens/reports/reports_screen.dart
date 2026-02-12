import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);

    final catLookup = <String, dynamic>{};
    for (final cat in categories.valueOrNull ?? []) {
      catLookup[cat.id] = cat;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
                    },
                  ),
                  Text(
                    selectedMonth.monthYear,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Builder(builder: (context) {
            if (categoryTotals.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No data this month',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            }

            final sorted = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final grandTotal = sorted.fold<double>(0, (s, e) => s + e.value);

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = sorted[index];
                  final cat = catLookup[entry.key];
                  final pct =
                      grandTotal > 0 ? (entry.value / grandTotal * 100) : 0.0;
                  final color =
                      AppColors.chartPalette[index % AppColors.chartPalette.length];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cat?.emoji ?? '📋',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat?.name ?? 'Unknown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontSize: 14),
                                    ),
                                    Text(
                                      '${pct.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(entry.value),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: grandTotal > 0 ? entry.value / grandTotal : 0,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            );
          }),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Daily Spending',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: transactions.when(
              data: (txns) {
                final dailyTotals = <int, double>{};
                final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

                for (final txn in txns) {
                  if (txn.isExpense) {
                    final day = txn.date.day;
                    dailyTotals[day] = (dailyTotals[day] ?? 0) + txn.amount;
                  }
                }

                if (dailyTotals.isEmpty) {
                  return const SizedBox.shrink();
                }

                final maxVal = dailyTotals.values.fold<double>(0, (a, b) => a > b ? a : b);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          maxY: maxVal * 1.2,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  'Day ${group.x}\n${CurrencyFormatter.format(rod.toY)}',
                                  const TextStyle(color: Colors.white, fontSize: 11),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() % 5 == 1) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${value.toInt()}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: List.generate(daysInMonth, (i) {
                            final day = i + 1;
                            final val = dailyTotals[day] ?? 0;
                            return BarChartGroupData(
                              x: day,
                              barRods: [
                                BarChartRodData(
                                  toY: val,
                                  color: val > 0
                                      ? AppColors.expense.withValues(alpha: 0.7)
                                      : Colors.transparent,
                                  width: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
