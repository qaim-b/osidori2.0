import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/themed_backdrop.dart';
import '../../widgets/transaction/transaction_tile.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(monthlyTransactionsProvider.notifier).load(),
      ref.read(categoriesProvider.notifier).load(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedMonthProvider);
    _displayedMonth = DateTime(selected.year, selected.month, 1);
    _selectedDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
      _selectedDay = null;
    });
    ref.read(selectedMonthProvider.notifier).state = _displayedMonth;
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
      _selectedDay = null;
    });
    ref.read(selectedMonthProvider.notifier).state = _displayedMonth;
  }

  @override
  Widget build(BuildContext context) {
    final roleColors = ref.watch(roleColorsProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(categoriesProvider);

    // Build category lookup map
    final catEntityMap = <String, CategoryEntity>{};
    for (final cat in categories.valueOrNull ?? <CategoryEntity>[]) {
      catEntityMap[cat.id] = cat;
    }

    // Compute daily totals from transactions
    final Map<int, double> dailyExpense = {};
    final Map<int, double> dailyIncome = {};
    transactions.whenData((txns) {
      for (final txn in txns) {
        final day = txn.date.day;
        if (txn.isExpense) {
          dailyExpense[day] = (dailyExpense[day] ?? 0) + txn.amount;
        } else if (txn.isIncome) {
          dailyIncome[day] = (dailyIncome[day] ?? 0) + txn.amount;
        }
      }
    });

    // Calendar grid info
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstWeekday = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    ).weekday;
    // Adjust to Monday=0 start
    final startOffset = (firstWeekday - 1) % 7;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemedBackdrop(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // App bar with month nav
              SliverAppBar(
                pinned: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _prevMonth,
                    ),
                    Text(
                      _displayedMonth.monthYear,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),

              // Monthly summary bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      _SummaryPill(
                        label: 'Income',
                        amount: dailyIncome.values.fold<double>(
                          0,
                          (s, v) => s + v,
                        ),
                        color: AppColors.income,
                      ),
                      const SizedBox(width: 8),
                      _SummaryPill(
                        label: 'Expense',
                        amount: dailyExpense.values.fold<double>(
                          0,
                          (s, v) => s + v,
                        ),
                        color: AppColors.expense,
                      ),
                    ],
                  ),
                ),
              ),

              // Weekday headers
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: d == 'Sun'
                                      ? AppColors.expense
                                      : (d == 'Sat'
                                            ? roleColors.primary
                                            : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              // Calendar grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: _buildCalendarRows(
                      daysInMonth: daysInMonth,
                      startOffset: startOffset,
                      dailyExpense: dailyExpense,
                      dailyIncome: dailyIncome,
                      roleColors: roleColors,
                    ),
                  ),
                ),
              ),

              // Selected day detail
              if (_selectedDay != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: roleColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('d MMMM').format(_selectedDay!)} Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDayTransactions(transactions, roleColors, catEntityMap),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarRows({
    required int daysInMonth,
    required int startOffset,
    required Map<int, double> dailyExpense,
    required Map<int, double> dailyIncome,
    required RoleColors roleColors,
  }) {
    final rows = <Widget>[];
    final today = DateTime.now();
    int dayCounter = 1;

    final totalCells = startOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    for (int row = 0; row < rowCount; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < startOffset || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 64)));
        } else {
          final day = dayCounter;
          final expense = dailyExpense[day] ?? 0;
          final income = dailyIncome[day] ?? 0;
          final isToday =
              today.year == _displayedMonth.year &&
              today.month == _displayedMonth.month &&
              today.day == day;
          final isSelected =
              _selectedDay != null &&
              _selectedDay!.year == _displayedMonth.year &&
              _selectedDay!.month == _displayedMonth.month &&
              _selectedDay!.day == day;

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month,
                      day,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 64,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? roleColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: roleColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: col == 6
                              ? AppColors.expense
                              : (col == 5
                                    ? roleColors.primary
                                    : AppColors.textPrimary),
                        ),
                      ),
                      if (expense > 0)
                        Text(
                          '-${_shortAmount(expense)}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (income > 0)
                        Text(
                          '+${_shortAmount(income)}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.income,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }

  Widget _buildDayTransactions(
    AsyncValue<List<TransactionModel>> transactions,
    RoleColors roleColors,
    Map<String, CategoryEntity> catEntityMap,
  ) {
    return transactions.when(
      data: (txns) {
        final dayTxns = txns.where((t) {
          return _selectedDay != null &&
              t.date.year == _selectedDay!.year &&
              t.date.month == _selectedDay!.month &&
              t.date.day == _selectedDay!.day;
        }).toList();

        if (dayTxns.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No transactions on this day',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final txn = dayTxns[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: TransactionTile(
                transaction: txn,
                category: catEntityMap[txn.categoryId],
                onTap: () => _showTransactionActions(context, txn),
              ),
            );
          }, childCount: dayTxns.length),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
    );
  }

  String _shortAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _showTransactionActions(
    BuildContext context,
    TransactionModel txn,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showEditDialog(context, txn);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.expense,
                ),
                title: const Text(
                  'Delete Transaction',
                  style: TextStyle(color: AppColors.expense),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (confirmCtx) {
                      return AlertDialog(
                        title: const Text('Delete Transaction?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(confirmCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(confirmCtx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await ref
                        .read(monthlyTransactionsProvider.notifier)
                        .deleteTransaction(txn.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    TransactionModel txn,
  ) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final filteredCategories =
        categories
            .where(
              (c) =>
                  c.isEnabled &&
                  ((txn.isExpense && c.isExpense) ||
                      (txn.isIncome && c.isIncome)),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final amountController = TextEditingController(
      text: txn.amount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: txn.note ?? '');
    DateTime selectedDate = txn.date;
    String selectedCategoryId = txn.categoryId;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Transaction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '¥ ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue:
                        filteredCategories.any(
                          (c) => c.id == selectedCategoryId,
                        )
                        ? selectedCategoryId
                        : (filteredCategories.isEmpty
                              ? null
                              : filteredCategories.first.id),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: filteredCategories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.displayLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategoryId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      final parsedAmount = double.tryParse(amountController.text.trim());
      if (parsedAmount == null || parsedAmount <= 0) return;

      final updatedTxn = TransactionModel(
        id: txn.id,
        type: txn.type,
        amount: parsedAmount,
        currency: txn.currency,
        date: selectedDate,
        categoryId: selectedCategoryId,
        categoryNameSnapshot: filteredCategories
            .where((c) => c.id == selectedCategoryId)
            .map((c) => c.name)
            .firstOrNull,
        categoryEmojiSnapshot: filteredCategories
            .where((c) => c.id == selectedCategoryId)
            .map((c) => c.emoji)
            .firstOrNull,
        categoryDisplayNumberSnapshot: filteredCategories
            .where((c) => c.id == selectedCategoryId)
            .map((c) => c.displayNumber)
            .firstOrNull,
        fromAccountId: txn.fromAccountId,
        toAccountId: txn.toAccountId,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        visibility: txn.visibility,
        ownerUserId: txn.ownerUserId,
        groupId: txn.groupId,
        source: txn.source,
        createdAt: txn.createdAt,
      );

      await ref
          .read(monthlyTransactionsProvider.notifier)
          .updateTransaction(updatedTxn);
    }
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              label == 'Income'
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
