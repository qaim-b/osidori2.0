import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/travel_mode_provider.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/common/editorial.dart';
import '../../widgets/common/themed_backdrop.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final ScrollController _scrollController = ScrollController();
  List<CategoryEntity> _cachedCategories = const [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _scrollMotion({
    required Widget child,
    required double start,
    double distance = 22,
  }) {
    if (kIsWeb) return child;
    return AnimatedBuilder(
      animation: _scrollController,
      child: child,
      builder: (context, child) {
        final offset = _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;
        final progress = ((offset - start) / 260).clamp(0.0, 1.0);
        return Opacity(
          opacity: (0.74 + (0.26 * progress)).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, distance * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(monthlyTransactionsProvider.notifier).load(),
      ref.read(categoriesProvider.notifier).load(),
      ref.read(budgetLimitsProvider.notifier).load(),
    ]);
  }

  Future<void> _showHideCategoriesSheet({
    required BuildContext context,
    required List<CategoryEntity> categories,
  }) async {
    final expenseCategories = categories.where((c) => c.isExpense).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (expenseCategories.isEmpty) return;

    final hiddenById = <String, bool>{
      for (final category in expenseCategories)
        category.id: category.isHiddenFromExpenseViews,
    };
    final pendingIds = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hiddenCount = hiddenById.values
                .where((hidden) => hidden)
                .length;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hide Categories',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        AnimatedContainer(
                          duration: AppMotion.normal,
                          curve: AppMotion.smooth,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$hiddenCount hidden',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Changes apply instantly to the budget page, totals, and category lists. No pull-to-refresh needed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: expenseCategories.length,
                        itemBuilder: (context, index) {
                          final category = expenseCategories[index];
                          final baseColor = _categoryAccent(category);
                          final isHidden = hiddenById[category.id] ?? false;
                          final isPending = pendingIds.contains(category.id);
                          final tileShade = baseColor.withValues(
                            alpha: isHidden ? 0.08 : 0.14,
                          );
                          return AnimatedContainer(
                            duration: AppMotion.normal,
                            curve: AppMotion.smooth,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tileShade,
                                  baseColor.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: baseColor.withValues(alpha: 0.18),
                              ),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              value: isHidden,
                              tileColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                '${category.displayNumber}. ${category.name}',
                              ),
                              subtitle: Text(
                                isPending
                                    ? (isHidden
                                          ? 'Hiding this category...'
                                          : 'Showing this category...')
                                    : (isHidden
                                          ? 'Hidden from monthly spending views'
                                          : 'Visible in monthly spending views'),
                              ),
                              activeThumbColor: baseColor,
                              activeTrackColor: baseColor.withValues(
                                alpha: 0.35,
                              ),
                              secondary: AnimatedSwitcher(
                                duration: AppMotion.fast,
                                switchInCurve: AppMotion.smooth,
                                switchOutCurve: AppMotion.dismiss,
                                child: isPending
                                    ? SizedBox(
                                        key: ValueKey('pending-${category.id}'),
                                        width: 34,
                                        height: 34,
                                        child: Padding(
                                          padding: const EdgeInsets.all(7),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  baseColor,
                                                ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        key: ValueKey('emoji-${category.id}'),
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: baseColor.withValues(
                                            alpha: 0.22,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: baseColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          category.emoji,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                              ),
                              onChanged: isPending
                                  ? null
                                  : (value) {
                                      setSheetState(() {
                                        hiddenById[category.id] = value;
                                        pendingIds.add(category.id);
                                      });
                                      () async {
                                        try {
                                          await ref
                                              .read(categoriesProvider.notifier)
                                              .toggleExpenseViewHidden(
                                                category.id,
                                                value,
                                              );
                                        } finally {
                                          if (context.mounted) {
                                            setSheetState(() {
                                              pendingIds.remove(category.id);
                                            });
                                          }
                                        }
                                      }();
                                    },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _categoryAccent(CategoryEntity category) {
    return _categoryAccentFromSeed(category.sortOrder);
  }

  Color _categoryAccentForRow(CategoryEntity? category, String fallbackKey) {
    final seed = category?.sortOrder ?? fallbackKey.hashCode;
    return _categoryAccentFromSeed(seed);
  }

  Color _categoryAccentFromSeed(int seed) {
    final palette = AppColors.chartPalette;
    final index = seed.abs() % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final travelMode = ref.watch(travelModeProvider);
    final monthlyTxns =
        ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
    final visibleTxns = ref.watch(visibleMonthlyTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final currentCurrency = ref.watch(currentCurrencyProvider);
    final preset = ref.watch(activeThemePresetDataProvider);
    final budgetLimitMap = ref.watch(budgetLimitMapProvider);
    final allCategories = categories.valueOrNull ?? _cachedCategories;
    final latestCategories = categories.valueOrNull;
    if (latestCategories != null) {
      _cachedCategories = latestCategories;
    }
    final hiddenExpenseCount = allCategories
        .where((c) => c.isExpense && c.isHiddenFromExpenseViews)
        .length;

    final honeymoonCategory = findHoneymoonCategory(allCategories);
    final honeymoonId = honeymoonCategory?.id;
    final travelModeActive = travelMode.enabled && honeymoonId != null;
    final txns = travelModeActive
        ? monthlyTxns.where((t) => t.categoryId == honeymoonId).toList()
        : visibleTxns;

    final catEntityMap = <String, CategoryEntity>{};
    final resolvedCategoryNameMap = <String, String>{};
    final resolvedCategoryEmojiMap = <String, String>{};
    final catSnapshotNameMap = <String, String>{};
    final catSnapshotEmojiMap = <String, String>{};

    for (final cat in allCategories) {
      catEntityMap[cat.id] = cat;
      resolvedCategoryNameMap[cat.id] = cat.name;
      resolvedCategoryEmojiMap[cat.id] = cat.emoji;
    }

    for (final txn in txns) {
      if (txn.categoryNameSnapshot != null &&
          txn.categoryNameSnapshot!.trim().isNotEmpty) {
        catSnapshotNameMap[txn.categoryId] = txn.categoryNameSnapshot!;
        resolvedCategoryNameMap[txn.categoryId] =
            resolvedCategoryNameMap[txn.categoryId] ??
            txn.categoryNameSnapshot!;
      }
      if (txn.categoryEmojiSnapshot != null &&
          txn.categoryEmojiSnapshot!.trim().isNotEmpty) {
        catSnapshotEmojiMap[txn.categoryId] = txn.categoryEmojiSnapshot!;
        resolvedCategoryEmojiMap[txn.categoryId] =
            resolvedCategoryEmojiMap[txn.categoryId] ??
            txn.categoryEmojiSnapshot!;
      }
      resolvedCategoryNameMap[txn.categoryId] =
          resolvedCategoryNameMap[txn.categoryId] ??
          (txn.categoryDisplayNumberSnapshot != null
              ? 'Category #${txn.categoryDisplayNumberSnapshot}'
              : 'Other');
      resolvedCategoryEmojiMap[txn.categoryId] =
          resolvedCategoryEmojiMap[txn.categoryId] ?? '📦';
    }

    final categoryTotals = <String, double>{};
    double incomeTotal = 0;
    double expenseTotal = 0;
    for (final txn in txns) {
      if (txn.isIncome) incomeTotal += txn.amount;
      if (txn.isExpense) {
        expenseTotal += txn.amount;
        categoryTotals[txn.categoryId] =
            (categoryTotals[txn.categoryId] ?? 0) + txn.amount;
      }
    }

    final breakdownTotals = <String, double>{};
    final breakdownNames = <String, String>{};
    for (final txn in txns) {
      if (!txn.isExpense) continue;
      final resolvedName = resolvedCategoryNameMap[txn.categoryId] ?? 'Other';
      final resolvedEmoji = resolvedCategoryEmojiMap[txn.categoryId] ?? '📦';
      final key = '$resolvedEmoji $resolvedName';
      breakdownTotals[key] = (breakdownTotals[key] ?? 0) + txn.amount;
      breakdownNames[key] = key;
    }
    final groupedRows = <String, _BudgetRowAggregate>{};
    final enabledExpenseCategories =
        travelModeActive
              ? [honeymoonCategory].nonNulls.toList()
              : allCategories
                    .where(
                      (c) =>
                          c.isExpense &&
                          c.isEnabled &&
                          !c.isHiddenFromExpenseViews,
                    )
                    .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Show all enabled expense categories, including zero-amount rows.
    for (final cat in enabledExpenseCategories) {
      groupedRows[cat.id] = _BudgetRowAggregate(
        categoryId: cat.id,
        name: cat.name,
        emoji: cat.emoji,
        amount: categoryTotals[cat.id] ?? 0,
        budgetLimit: budgetLimitMap[cat.id] ?? 0,
      );
    }

    // Merge any transaction-only categories not present in current enabled list.
    for (final entry in categoryTotals.entries) {
      final categoryId = entry.key;
      final name =
          resolvedCategoryNameMap[categoryId] ??
          catSnapshotNameMap[categoryId] ??
          'Other';
      final emoji =
          resolvedCategoryEmojiMap[categoryId] ??
          catSnapshotEmojiMap[categoryId] ??
          '📦';
      final current = groupedRows[categoryId];
      final budgetLimit = budgetLimitMap[categoryId] ?? 0;
      if (current == null) {
        groupedRows[categoryId] = _BudgetRowAggregate(
          categoryId: categoryId,
          name: name,
          emoji: emoji,
          amount: entry.value,
          budgetLimit: budgetLimit,
        );
      } else {
        groupedRows[categoryId] = current.copyWith(
          amount: entry.value,
          budgetLimit: budgetLimit,
        );
      }
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemedBackdrop(
        showCountryBanner: true,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            controller: _scrollController,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
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
              SliverToBoxAdapter(
                child: _scrollMotion(
                  start: 24,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: preset.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                color: preset.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                CurrencyFormatter.format(
                                  incomeTotal,
                                  currency: currentCurrency,
                                ),
                                style: TextStyle(
                                  color: preset.primary,
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
                            gradient: LinearGradient(
                              colors: [preset.primary, preset.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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
                                  expenseTotal,
                                  currency: currentCurrency,
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
              ),
              SliverToBoxAdapter(
                child: _scrollMotion(
                  start: 90,
                  child: EditorialCard(
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    accentTop: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    preset.primary.withValues(alpha: 0.85),
                                    preset.secondary.withValues(alpha: 0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.flight_takeoff_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Travel Mode',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    travelModeActive
                                        ? 'Showing only Honeymoon expenses'
                                        : 'Focus the budget on travel spending',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: travelMode.enabled,
                              onChanged: travelMode.isLoading
                                  ? null
                                  : (value) => ref
                                        .read(travelModeProvider.notifier)
                                        .setEnabled(value),
                              activeTrackColor: preset.primary.withValues(
                                alpha: 0.35,
                              ),
                              activeThumbColor: preset.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (travelMode.enabled && honeymoonCategory == null)
                          Text(
                            'Honeymoon category not found. Create it in Categories to use Travel Mode.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: preset.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  travelMode.destination.trim().isEmpty
                                      ? 'Set destination'
                                      : travelMode.destination.trim(),
                                  style: TextStyle(
                                    color: preset.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showTravelDestinationSheet(
                                  context: context,
                                  initial: travelMode.destination,
                                ),
                                icon: const Icon(Icons.edit_location_alt),
                                label: const Text('Edit'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _scrollMotion(
                  start: 120,
                  child: EditorialCard(
                    margin: const EdgeInsets.all(16),
                    accentTop: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Breakdown',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final total = breakdownTotals.values.fold<double>(
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
                              key: ValueKey(
                                '${selectedMonth.year}-${selectedMonth.month}-$travelModeActive-${breakdownTotals.length}-$total',
                              ),
                              categoryTotals: breakdownTotals,
                              categoryNames: breakdownNames,
                              currency: currentCurrency,
                              totalAmount: total,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _scrollMotion(
                  start: 240,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          travelModeActive
                              ? 'Travel Categories'
                              : 'By Category',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: categories.isLoading
                                  ? null
                                  : () => _showHideCategoriesSheet(
                                      context: context,
                                      categories: allCategories,
                                    ),
                              icon: const Icon(
                                Icons.visibility_off_rounded,
                                size: 18,
                              ),
                              label: Text(
                                hiddenExpenseCount == 0
                                    ? 'Hide Categories'
                                    : 'Hidden ($hiddenExpenseCount)',
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => context.push('/budget/planner'),
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('All Budgets'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final total = groupedRows.values.fold<double>(
                    0,
                    (sum, v) => sum + v.amount,
                  );
                  final sorted = groupedRows.values.toList()
                    ..sort((a, b) => b.amount.compareTo(a.amount));

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
                      final cat = catEntityMap[entry.categoryId];
                      final pct = total > 0
                          ? (entry.amount / total * 100)
                          : 0.0;
                      final budgetLimit = entry.budgetLimit > 0
                          ? entry.budgetLimit
                          : null;
                      final accentColor = _categoryAccentForRow(
                        cat,
                        entry.categoryId,
                      );
                      final limitProgress = budgetLimit != null
                          ? (entry.amount / budgetLimit).clamp(0.0, 1.5)
                          : null;

                      return EditorialCard(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(
                            '/budget/category/${entry.categoryId}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 360;

                                Widget amountSummary({
                                  required CrossAxisAlignment alignment,
                                  required MainAxisAlignment badgeAlignment,
                                }) {
                                  return Column(
                                    crossAxisAlignment: alignment,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(end: entry.amount),
                                        duration: const Duration(
                                          milliseconds: 350,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Text(
                                            CurrencyFormatter.format(
                                              value,
                                              currency: currentCurrency,
                                            ),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 14.8,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: badgeAlignment,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(
                                              minWidth: 64,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${pct.toStringAsFixed(1)}%',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13.4,
                                                fontWeight: FontWeight.w800,
                                                color: accentColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: isCompact ? 44 : 32,
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        CircleAvatar(
                                          backgroundColor: accentColor
                                              .withValues(alpha: 0.18),
                                          child: Text(
                                            cat?.emoji ?? entry.emoji,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cat?.name ?? entry.name,
                                                maxLines: isCompact ? 2 : 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (isCompact) ...[
                                                const SizedBox(height: 10),
                                                amountSummary(
                                                  alignment:
                                                      CrossAxisAlignment.start,
                                                  badgeAlignment:
                                                      MainAxisAlignment.start,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (!isCompact) ...[
                                          const SizedBox(width: 8),
                                          amountSummary(
                                            alignment: CrossAxisAlignment.end,
                                            badgeAlignment:
                                                MainAxisAlignment.end,
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: isCompact ? 2 : 8,
                                          ),
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: preset.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (budgetLimit != null) ...[
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          minHeight: 6,
                                          value:
                                              limitProgress?.clamp(0.0, 1.0) ??
                                              0,
                                          backgroundColor: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                (limitProgress ?? 0) <= 1
                                                    ? preset.primary
                                                    : AppColors.expense,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: isCompact
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        child: Text(
                                          'Budget ${CurrencyFormatter.format(budgetLimit, currency: currentCurrency)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }, childCount: sorted.length),
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

  Future<void> _showTravelDestinationSheet({
    required BuildContext context,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Travel Destination',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g. Turkey, Seoul, Bali',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(travelModeProvider.notifier)
                        .setDestination(controller.text);
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Save Destination'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetRowAggregate {
  final String categoryId;
  final String name;
  final String emoji;
  final double amount;
  final double budgetLimit;

  const _BudgetRowAggregate({
    required this.categoryId,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.budgetLimit,
  });

  _BudgetRowAggregate copyWith({
    String? categoryId,
    String? name,
    String? emoji,
    double? amount,
    double? budgetLimit,
  }) {
    return _BudgetRowAggregate(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      amount: amount ?? this.amount,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }
}
