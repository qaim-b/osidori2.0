import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final Map<String, String> categoryNames;
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
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No data', style: TextStyle(fontSize: 16)),
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

    final sorted = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final percentage = widget.totalAmount <= 0
          ? 0
          : (entry.value / widget.totalAmount) * 100;
      final color = AppColors.chartPalette[i % AppColors.chartPalette.length];
      final isTouched = i == _touchedIndex;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: isTouched ? 38 : 32,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
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
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!mounted) return;
                      final touched =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                      setState(() => _touchedIndex = touched);
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.compact(
                      widget.totalAmount,
                      currency: widget.currency,
                    ),
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
        if (_touchedIndex >= 0 && _touchedIndex < sorted.length) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final touched = sorted[_touchedIndex];
              final color = AppColors
                  .chartPalette[_touchedIndex % AppColors.chartPalette.length];
              final name = widget.categoryNames[touched.key] ?? touched.key;
              final pct = widget.totalAmount <= 0
                  ? 0.0
                  : (touched.value / widget.totalAmount) * 100;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(touched.value)} (${pct.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(sorted.length, (i) {
            final entry = sorted[i];
            final color = AppColors.chartPalette[i % AppColors.chartPalette.length];
            final name = widget.categoryNames[entry.key] ?? entry.key;
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
                Text(name, style: const TextStyle(fontSize: 11)),
              ],
            );
          }),
        ),
      ],
    );
  }
}
