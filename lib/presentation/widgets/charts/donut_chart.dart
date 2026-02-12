import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Category breakdown donut chart — pastel colors, cute center text.
class CategoryDonutChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final Map<String, String> categoryNames; // id -> "emoji name"
  final String currency;
  final double totalAmount;

  const CategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.categoryNames,
    required this.currency,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'No expenses yet',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Add your first transaction!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by amount descending for consistent chart ordering
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final percentage = (entry.value / totalAmount) * 100;
      final color =
          AppColors.chartPalette[i % AppColors.chartPalette.length];

      sections.add(PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 32,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
              // Center total
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  Text(
                    CurrencyFormatter.compact(totalAmount, currency: currency),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(sorted.length.clamp(0, 8), (i) {
            final entry = sorted[i];
            final color =
                AppColors.chartPalette[i % AppColors.chartPalette.length];
            final name = categoryNames[entry.key] ?? 'Unknown';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
