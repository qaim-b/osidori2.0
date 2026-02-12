import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';

class SetBudgetLimitScreen extends ConsumerStatefulWidget {
  const SetBudgetLimitScreen({super.key});

  @override
  ConsumerState<SetBudgetLimitScreen> createState() => _SetBudgetLimitScreenState();
}

class _SetBudgetLimitScreenState extends ConsumerState<SetBudgetLimitScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final limits = ref.watch(budgetLimitMapProvider);
    final expenseCategories =
        categories.where((c) => c.isExpense && c.isEnabled).toList()
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
      appBar: AppBar(title: const Text('Set Budget Limits')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
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
                  Expanded(child: Text(cat.name)),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _controllers[cat.id],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: '0',
                        isDense: true,
                        prefixText: '¥ ',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final notifier = ref.read(budgetLimitsProvider.notifier);
              for (final cat in expenseCategories) {
                final value = double.tryParse(_controllers[cat.id]?.text.trim() ?? '');
                if (value != null && value > 0) {
                  await notifier.setLimit(categoryId: cat.id, amount: value);
                }
              }
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Budget limits saved'),
                  backgroundColor: AppColors.success,
                ),
              );
              navigator.pop();
            },
            child: const Text('Save All'),
          ),
        ),
      ),
    );
  }
}
