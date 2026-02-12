import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/category_defaults.dart';
import '../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '📤 Expense'),
            Tab(text: '📥 Income'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenses =
              categories.where((c) => c.isExpense).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final incomes =
              categories.where((c) => c.isIncome).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryList(
                  categories: expenses, parentDefs: CategoryDefaults.parentCategories),
              _CategoryList(
                  categories: incomes, parentDefs: const []),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final List<CategoryModel> categories;
  final List<ParentCategoryDef> parentDefs;

  const _CategoryList({
    required this.categories,
    required this.parentDefs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories'));
    }

    // Group by parentKey
    final grouped = <String, List<CategoryModel>>{};
    for (final cat in categories) {
      final key = cat.parentKey ?? 'other';
      grouped.putIfAbsent(key, () => []).add(cat);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final parentKey = grouped.keys.elementAt(index);
        final children = grouped[parentKey]!;
        final parentDef = parentDefs.isEmpty
            ? null
            : parentDefs.where((p) => p.key == parentKey).firstOrNull;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parent header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    Text(
                      parentDef?.emoji ?? '📋',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      parentDef?.name ?? parentKey,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Sub-categories with toggle
              ...children.map((cat) => _CategoryTile(category: cat)),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final CategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Text(category.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        '${category.displayNumber}. ${category.name}',
        style: TextStyle(
          fontSize: 14,
          color: category.isEnabled
              ? AppColors.textPrimary
              : AppColors.textHint,
          decoration:
              category.isEnabled ? null : TextDecoration.lineThrough,
        ),
      ),
      trailing: Switch.adaptive(
        value: category.isEnabled,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        activeThumbColor: AppColors.primary,
        onChanged: (val) {
          ref
              .read(categoriesProvider.notifier)
              .toggleEnabled(category.id, val);
        },
      ),
      dense: true,
    );
  }
}
