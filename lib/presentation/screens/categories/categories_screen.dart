import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/category_defaults.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../providers/category_provider.dart';

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
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(
          context,
          ref,
          _tabController.index == 0 ? 'expense' : 'income',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenses = categories.where((c) => c.isExpense).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final incomes = categories.where((c) => c.isIncome).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryList(
                categories: expenses,
                parentDefs: CategoryDefaults.parentCategories,
              ),
              _CategoryList(categories: incomes, parentDefs: const []),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final existing = categories.where((c) => c.type == type).toList();
    final maxNumber = existing.isEmpty
        ? 0
        : existing.map((e) => e.displayNumber).reduce((a, b) => a > b ? a : b);

    final emojiController = TextEditingController(
      text: type == 'expense' ? '🧾' : '💰',
    );
    final nameController = TextEditingController();
    final numberController = TextEditingController(text: '${maxNumber + 1}');
    String? parentKey = type == 'income'
        ? 'income'
        : CategoryDefaults.parentCategories.first.key;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${type == 'expense' ? 'Expense' : 'Income'} Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: 'Emoji'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display Number'),
              ),
              if (type == 'expense') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: parentKey,
                  items: CategoryDefaults.parentCategories
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.key,
                          child: Text('${p.emoji} ${p.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => parentKey = v,
                  decoration: const InputDecoration(labelText: 'Parent'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final number = int.tryParse(numberController.text.trim());
              final name = nameController.text.trim();
              if (number == null || name.isEmpty) return;
              await ref
                  .read(categoriesProvider.notifier)
                  .addCategory(
                    type: type,
                    name: name,
                    emoji: emojiController.text.trim().isEmpty
                        ? '🧾'
                        : emojiController.text.trim(),
                    displayNumber: number,
                    parentKey: parentKey,
                  );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final List<CategoryModel> categories;
  final List<ParentCategoryDef> parentDefs;

  const _CategoryList({required this.categories, required this.parentDefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories'));
    }

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
          decoration: category.isEnabled ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Text(category.type),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _showEditDialog(context, ref, category),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref, category),
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.expense,
              size: 18,
            ),
          ),
          Switch.adaptive(
            value: category.isEnabled,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              ref
                  .read(categoriesProvider.notifier)
                  .toggleEnabled(category.id, val);
            },
          ),
        ],
      ),
      dense: true,
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final emojiController = TextEditingController(text: category.emoji);
    final nameController = TextEditingController(text: category.name);
    final numberController = TextEditingController(
      text: category.displayNumber.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Display Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final number = int.tryParse(numberController.text.trim());
              if (number == null || nameController.text.trim().isEmpty) return;
              final updated = CategoryModel(
                id: category.id,
                displayNumber: number,
                name: nameController.text.trim(),
                emoji: emojiController.text.trim().isEmpty
                    ? category.emoji
                    : emojiController.text.trim(),
                type: category.type,
                parentId: category.parentId,
                parentKey: category.parentKey,
                isEnabled: category.isEnabled,
                sortOrder: number,
                createdAt: category.createdAt,
              );
              await ref
                  .read(categoriesProvider.notifier)
                  .updateCategory(updated);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Delete "${category.displayNumber}. ${category.name}"? Existing transactions keep their category id.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Category deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}
