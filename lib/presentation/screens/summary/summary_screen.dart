import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/fx_converter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/themed_backdrop.dart';

enum _ExportScope { current, picked, lastSixMonths, allMonths }

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(monthlyTransactionsProvider.notifier).load(),
      ref.read(categoriesProvider.notifier).load(),
      ref.read(goalsProvider.notifier).load(),
      ref.read(budgetLimitsProvider.notifier).load(),
    ]);
  }

  Future<DateTime?> _pickExportMonth(DateTime initialMonth) async {
    final monthNames = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    var displayYear = initialMonth.year;
    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Choose Month',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setLocalState(() => displayYear -= 1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Text(
                          '$displayYear',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setLocalState(() => displayYear += 1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.2,
                      ),
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected =
                            initialMonth.year == displayYear &&
                                initialMonth.month == month;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(
                            DateTime(displayYear, month, 1),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              monthNames[index],
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
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

  Future<_ExportScope?> _pickExportScope(String title) {
    return showModalBottomSheet<_ExportScope>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Export selected month'),
                  subtitle: const Text('Current month shown on Summary'),
                  onTap: () => Navigator.of(context).pop(_ExportScope.current),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_calendar_rounded),
                  title: const Text('Export specific month'),
                  subtitle: const Text('Pick February 2026, March 2026, etc.'),
                  onTap: () => Navigator.of(context).pop(_ExportScope.picked),
                ),
                ListTile(
                  leading: const Icon(Icons.timeline_rounded),
                  title: const Text('Export last 6 months'),
                  subtitle: const Text('Portable monthly package'),
                  onTap: () =>
                      Navigator.of(context).pop(_ExportScope.lastSixMonths),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_motion_rounded),
                  title: const Text('Export all months individually'),
                  subtitle: const Text('One file per month'),
                  onTap: () => Navigator.of(context).pop(_ExportScope.allMonths),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<TransactionModel>> _loadTransactionsForExport({
    required DateTime exportMonth,
    required String displayCurrency,
    required String fxMode,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return [];
    final groupIds = ref.read(groupIdsProvider);
    final repo = ref.read(transactionRepositoryProvider);
    final raw = await repo.getForMonth(
      userId: userId,
      year: exportMonth.year,
      month: exportMonth.month,
      groupIds: groupIds,
    );

    return Future.wait(
      raw.map((txn) async {
        if (fxMode == 'accounting' &&
            txn.fxBaseCurrency?.toUpperCase() == displayCurrency.toUpperCase() &&
            txn.baseAmountLocked != null) {
          return txn.copyWith(
            amount: txn.baseAmountLocked,
            currency: displayCurrency,
          );
        }
        if (txn.currency.toUpperCase() == displayCurrency.toUpperCase()) {
          return txn;
        }
        final converted = await FxConverter.convert(
          amount: txn.amount,
          fromCurrency: txn.currency,
          toCurrency: displayCurrency,
        );
        return txn.copyWith(amount: converted, currency: displayCurrency);
      }),
    );
  }

  Future<List<DateTime>> _loadAvailableHistoryMonths() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return [];
    final groupIds = ref.read(groupIdsProvider);
    final repo = ref.read(transactionRepositoryProvider);
    final raw = await repo.getForUser(
      userId: userId,
      groupIds: groupIds,
      from: DateTime(2020, 1, 1),
      to: DateTime(2100, 12, 31),
      pageSize: 100000,
    );
    final seen = <String>{};
    final months = <DateTime>[];
    for (final txn in raw) {
      final month = DateTime(txn.date.year, txn.date.month, 1);
      final key = '${month.year}-${month.month}';
      if (seen.add(key)) {
        months.add(month);
      }
    }
    months.sort((a, b) => a.compareTo(b));
    return months;
  }

  Future<void> _exportPlanningSummary({
    required _ExportScope scope,
    required DateTime selectedMonth,
    required String displayCurrency,
    required String fxMode,
    required List<CategoryEntity> categories,
    required Map<String, double> budgetLimits,
  }) async {
    final catNameMap = <String, String>{
      for (final c in categories.where((c) => c.isExpense)) c.id: c.shortLabel,
    };
    if (scope == _ExportScope.current || scope == _ExportScope.picked) {
      final exportMonth = scope == _ExportScope.current
          ? DateTime(selectedMonth.year, selectedMonth.month, 1)
          : await _pickExportMonth(DateTime(selectedMonth.year, selectedMonth.month, 1));
      if (exportMonth == null) return;
      final exportTxns = await _loadTransactionsForExport(
        exportMonth: exportMonth,
        displayCurrency: displayCurrency,
        fxMode: fxMode,
      );
      final path = await CsvExporter.exportExpenseCategoryMatrixXlsx(
        transactions: exportTxns,
        categoryNames: catNameMap,
        year: exportMonth.year,
        month: exportMonth.month,
        budgetLimits: budgetLimits,
      );
      await CsvExporter.shareFile(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Planning summary exported (${exportMonth.monthYear})')),
      );
      return;
    }

    if (kIsWeb && scope != _ExportScope.current && scope != _ExportScope.picked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Multi-file export is supported on app builds. On web, export one month at a time.',
          ),
        ),
      );
      return;
    }

    final months = await _loadAvailableHistoryMonths();
    final exportMonths = scope == _ExportScope.lastSixMonths
        ? months.reversed.take(6).toList().reversed.toList()
        : months;
    if (exportMonths.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found to export.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${exportMonths.length} month files...')),
    );
    final paths = <String>[];
    for (final month in exportMonths) {
      final exportTxns = await _loadTransactionsForExport(
        exportMonth: month,
        displayCurrency: displayCurrency,
        fxMode: fxMode,
      );
      final path = await CsvExporter.exportExpenseCategoryMatrixXlsx(
        transactions: exportTxns,
        categoryNames: catNameMap,
        year: month.year,
        month: month.month,
        budgetLimits: budgetLimits,
      );
      if (!path.startsWith('web://')) {
        paths.add(path);
      }
    }
    await CsvExporter.shareFiles(paths);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${exportMonths.length} monthly planning files'),
      ),
    );
  }

  Future<void> _exportTransactions({
    required _ExportScope scope,
    required DateTime selectedMonth,
    required String displayCurrency,
    required String fxMode,
    required List<CategoryEntity> categories,
  }) async {
    final catNameMap = <String, String>{
      for (final c in categories) c.id: c.shortLabel,
    };
    if (scope == _ExportScope.current || scope == _ExportScope.picked) {
      final exportMonth = scope == _ExportScope.current
          ? DateTime(selectedMonth.year, selectedMonth.month, 1)
          : await _pickExportMonth(DateTime(selectedMonth.year, selectedMonth.month, 1));
      if (exportMonth == null) return;
      final exportTxns = await _loadTransactionsForExport(
        exportMonth: exportMonth,
        displayCurrency: displayCurrency,
        fxMode: fxMode,
      );
      final path = await CsvExporter.exportTransactionsXlsx(
        transactions: exportTxns,
        categoryNames: catNameMap,
        year: exportMonth.year,
        month: exportMonth.month,
      );
      await CsvExporter.shareFile(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions exported (${exportMonth.monthYear})')),
      );
      return;
    }

    if (kIsWeb && scope != _ExportScope.current && scope != _ExportScope.picked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Multi-file export is supported on app builds. On web, export one month at a time.',
          ),
        ),
      );
      return;
    }

    final months = await _loadAvailableHistoryMonths();
    final exportMonths = scope == _ExportScope.lastSixMonths
        ? months.reversed.take(6).toList().reversed.toList()
        : months;
    if (exportMonths.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found to export.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${exportMonths.length} month files...')),
    );
    final paths = <String>[];
    for (final month in exportMonths) {
      final exportTxns = await _loadTransactionsForExport(
        exportMonth: month,
        displayCurrency: displayCurrency,
        fxMode: fxMode,
      );
      final path = await CsvExporter.exportTransactionsXlsx(
        transactions: exportTxns,
        categoryNames: catNameMap,
        year: month.year,
        month: month.month,
      );
      if (!path.startsWith('web://')) {
        paths.add(path);
      }
    }
    await CsvExporter.shareFiles(paths);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${exportMonths.length} monthly transaction files'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = ref.watch(monthlyTotalsProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final budgetLimits = ref.watch(budgetLimitMapProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? <CategoryEntity>[];
    final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currentCurrency = ref.watch(currentCurrencyProvider);
    final currentFxMode = ref.watch(currentFxDisplayModeProvider);
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
        showCountryBanner: true,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          ref.read(selectedMonthProvider.notifier).state = DateTime(
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
                          ref.read(selectedMonthProvider.notifier).state = DateTime(
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
                                value: CurrencyFormatter.format(
                                  income,
                                  currency: currentCurrency,
                                ),
                                icon: Icons.arrow_upward_rounded,
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricPill(
                                label: 'Expense',
                                value: CurrencyFormatter.format(
                                  expense,
                                  currency: currentCurrency,
                                ),
                                icon: Icons.arrow_downward_rounded,
                                color: AppColors.expense,
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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
                                              '\u{1F4CB}',
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
                                          '${CurrencyFormatter.format(actual, currency: currentCurrency)} / ${CurrencyFormatter.format(limit, currency: currentCurrency)}',
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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
                                          '\u{1F4CB}',
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
                                      '${CurrencyFormatter.format(entry.value, currency: currentCurrency)} (${pct.toStringAsFixed(1)}%)',
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
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InsightChip(
                          icon: Icons.calendar_today_rounded,
                          text:
                              'Daily avg: ${CurrencyFormatter.format(dailyAverage, currency: currentCurrency)}',
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
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.table_chart_rounded),
                          title: const Text('Export Planning Summary XLSX'),
                          subtitle: const Text(
                            'Current month, specific month, or all months individually',
                          ),
                          onTap: () async {
                            final scope = await _pickExportScope(
                              'Planning Summary Export',
                            );
                            if (scope == null) return;
                            await _exportPlanningSummary(
                              scope: scope,
                              selectedMonth: selectedMonth,
                              displayCurrency: currentCurrency,
                              fxMode: currentFxMode,
                              categories: categories,
                              budgetLimits: budgetLimits,
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.download_rounded),
                          title: const Text('Export Standard Transactions XLSX'),
                          subtitle: const Text(
                            'Current month, specific month, or all months individually',
                          ),
                          onTap: () async {
                            final scope = await _pickExportScope(
                              'Transactions Export',
                            );
                            if (scope == null) return;
                            await _exportTransactions(
                              scope: scope,
                              selectedMonth: selectedMonth,
                              displayCurrency: currentCurrency,
                              fxMode: currentFxMode,
                              categories: categories,
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
        color: Colors.white.withValues(alpha: 0.9),
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
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
