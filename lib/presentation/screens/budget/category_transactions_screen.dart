import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction/transaction_tile.dart';

class CategoryTransactionsScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);

    final categoryList = categories.valueOrNull ?? <CategoryEntity>[];
    CategoryEntity? category;
    for (final item in categoryList) {
      if (item.id == categoryId) {
        category = item;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category == null ? 'Category' : '${category.emoji} ${category.name}'),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: transactions.when(
        data: (txns) {
          final filtered = txns.where((t) => t.categoryId == categoryId).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final total = filtered.fold<double>(0, (sum, t) => sum + t.amount);

          if (filtered.isEmpty) {
            return const Center(child: Text('No transactions for this category this month'));
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Total: ${CurrencyFormatter.format(total)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                      child: TransactionTile(
                        transaction: filtered[index],
                        category: category,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
