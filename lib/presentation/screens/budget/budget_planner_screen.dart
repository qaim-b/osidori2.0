import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';

class BudgetPlannerScreen extends ConsumerStatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  ConsumerState<BudgetPlannerScreen> createState() =>
      _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends ConsumerState<BudgetPlannerScreen> {
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final limits = ref.watch(budgetLimitMapProvider);
    final query = _searchController.text.trim().toLowerCase();

    final expenseCategories =
        categories
            .where((c) => c.isExpense && c.isEnabled)
            .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final cat in expenseCategories) {
      _controllers.putIfAbsent(
        cat.id,
        () => TextEditingController(
          text: limits[cat.id]?.toStringAsFixed(0) ?? '',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Planner')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search category',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: expenseCategories.length,
              itemBuilder: (context, index) {
                final cat = expenseCategories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(cat.displayLabel)),
                        SizedBox(
                          width: 178,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controllers[cat.id],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: 'none',
                                    helperText: '0 = none',
                                    isDense: true,
                                    prefixText: '¥ ',
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Reset budget',
                                onPressed: () => _controllers[cat.id]?.clear(),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () async {
                  final notifier = ref.read(budgetLimitsProvider.notifier);
                  final existing =
                      ref.read(budgetLimitsProvider).valueOrNull ?? [];
                  for (final cat in expenseCategories) {
                    final raw = _controllers[cat.id]?.text.trim() ?? '';
                    final parsed = double.tryParse(raw);
                    if (parsed != null && parsed > 0) {
                      await notifier.setLimit(
                        categoryId: cat.id,
                        amount: parsed,
                      );
                    } else {
                      final target = existing
                          .where((l) => l.categoryId == cat.id)
                          .firstOrNull;
                      if (target != null) {
                        await notifier.removeLimit(target.id);
                      }
                    }
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget planner saved'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Planner'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
