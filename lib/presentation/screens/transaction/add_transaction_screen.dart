import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/enums/visibility_type.dart';
import '../../../domain/enums/account_type.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/account_entity.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  final VisibilityType _visibility = VisibilityType.shared;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _categoryQuery = '';
  DateTime _date = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedFromAccountId;
  String? _selectedToAccountId;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    if (_selectedFromAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an account')));
      return;
    }
    if (_type == TransactionType.transfer && _selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select destination account')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appCurrency = ref.read(currentCurrencyProvider);
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      CategoryEntity? selectedCategory;
      for (final c in categories) {
        if (c.id == _selectedCategoryId) {
          selectedCategory = c;
          break;
        }
      }
      final activeGroupId = ref.read(activeGroupIdProvider);
      await ref
          .read(monthlyTransactionsProvider.notifier)
          .addTransaction(
            type: _type,
            amount: amount,
            currency: appCurrency,
            date: _date,
            categoryId: _selectedCategoryId!,
            categoryNameSnapshot: selectedCategory?.name,
            categoryEmojiSnapshot: selectedCategory?.emoji,
            categoryDisplayNumberSnapshot: selectedCategory?.displayNumber,
            fromAccountId: _selectedFromAccountId!,
            toAccountId: _selectedToAccountId,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
            visibility: _visibility,
            groupId: activeGroupId,
          );

      if (mounted) {
        // Show cute success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✨ '),
                Text(
                  _type == TransactionType.expense
                      ? 'Expense added!'
                      : (_type == TransactionType.income
                            ? 'Income added!'
                            : 'Transfer recorded!'),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final categories = categoriesAsync.valueOrNull ?? [];
    final accounts = accountsAsync.valueOrNull ?? [];

    // Filter categories by transaction type
    final filteredCategories =
        _type == TransactionType.transfer
              ? <CategoryEntity>[]
              : categories
                    .where(
                      (c) =>
                          c.isEnabled &&
                          ((_type == TransactionType.expense && c.isExpense) ||
                              (_type == TransactionType.income && c.isIncome)),
                    )
                    .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final visibleCategories = _categoryQuery.trim().isEmpty
        ? filteredCategories
        : filteredCategories.where((c) {
            final q = _categoryQuery.trim().toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.emoji.contains(q) ||
                c.displayNumber.toString().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction type selector
            Row(
              children: TransactionType.values.map((type) {
                final isSelected = _type == type;
                final color = type == TransactionType.expense
                    ? AppColors.expense
                    : (type == TransactionType.income
                          ? AppColors.income
                          : AppColors.transfer);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = type;
                      _selectedCategoryId = null;
                    }),
                    child: AnimatedContainer(
                      duration: AppMotion.normal,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(type.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? color
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Amount input — BIG and prominent
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '¥',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    autofocus: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date picker
            _SectionTile(
              icon: Icons.calendar_today,
              label: 'Date',
              value: DateFormat('EEE, MMM d, yyyy').format(_date),
              onTap: _pickDate,
            ),

            const SizedBox(height: 12),

            // Account selector
            _SectionLabel(
              label: _type == TransactionType.transfer
                  ? 'From Account'
                  : 'Account',
            ),
            const SizedBox(height: 8),
            _AccountPicker(
              accounts: accounts,
              selectedId: _selectedFromAccountId,
              onSelect: (id) => setState(() => _selectedFromAccountId = id),
            ),

            // To account (transfer only)
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'To Account'),
              const SizedBox(height: 8),
              _AccountPicker(
                accounts: accounts
                    .where((a) => a.id != _selectedFromAccountId)
                    .toList(),
                selectedId: _selectedToAccountId,
                onSelect: (id) => setState(() => _selectedToAccountId = id),
              ),
            ],

            // Category selector (not for transfers)
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 16),
              _SectionLabel(
                label:
                    '${_type == TransactionType.expense ? 'Expense' : 'Income'} Category',
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) => setState(() => _categoryQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search category (name / number / emoji)',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              _CategoryPicker(
                categories: visibleCategories,
                selectedId: _selectedCategoryId,
                onSelect: (id) => setState(() => _selectedCategoryId = id),
                searchQuery: _categoryQuery,
              ),
            ],

            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    "Add a Note (Optional, let's help each other understand each item more ❤️)",
                prefixIcon: const Icon(Icons.notes, size: 20),
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.dreamyGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSaving ? null : _save,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              '✨ Save Transaction',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SectionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final String searchQuery;

  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No categories available'),
      );
    }

    final grouped = <String, List<CategoryEntity>>{};
    for (final cat in categories) {
      final key = (cat.parentKey == null || cat.parentKey!.trim().isEmpty)
          ? 'other'
          : cat.parentKey!;
      grouped.putIfAbsent(key, () => <CategoryEntity>[]).add(cat);
    }
    final groupKeys = grouped.keys.toList()..sort();
    final selected = categories.where((c) => c.id == selectedId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(selected.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${selected.displayLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groupKeys.map((groupKey) {
            final groupCats = grouped[groupKey]!;
            return GestureDetector(
              onTap: () => _openGroupPicker(
                context: context,
                groupKey: groupKey,
                items: groupCats,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _groupLabel(groupKey),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${groupCats.length})',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _groupLabel(String raw) {
    if (raw == 'other') return 'Other';
    return raw
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Future<void> _openGroupPicker({
    required BuildContext context,
    required String groupKey,
    required List<CategoryEntity> items,
  }) async {
    String q = searchQuery.trim().toLowerCase();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final liftOffset = MediaQuery.of(ctx).size.height * 0.12;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              24,
              12,
              14 + liftOffset + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                final visible = q.isEmpty
                    ? items
                    : items.where((c) {
                        return c.name.toLowerCase().contains(q) ||
                            c.emoji.contains(q) ||
                            c.displayNumber.toString().contains(q);
                      }).toList();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.72,
                    ),
                    color: Theme.of(ctx).colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(top: 10, bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        ListTile(
                          title: Text(_groupLabel(groupKey)),
                          subtitle: const Text('Choose category'),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: TextField(
                            onChanged: (value) => setSheetState(
                              () => q = value.trim().toLowerCase(),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search in this group',
                              prefixIcon: Icon(Icons.search, size: 20),
                            ),
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            shrinkWrap: true,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final cat = visible[index];
                              return ListTile(
                                leading: Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: cat.id == selectedId
                                        ? AppColors.primary.withValues(
                                            alpha: 0.14,
                                          )
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(cat.emoji),
                                ),
                                title: Text(cat.displayLabel),
                                tileColor: cat.id == selectedId
                                    ? AppColors.primary.withValues(alpha: 0.06)
                                    : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                trailing: cat.id == selectedId
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () => Navigator.of(ctx).pop(cat.id),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (chosen != null) {
      onSelect(chosen);
    }
  }
}

class _AccountPicker extends StatefulWidget {
  final List<AccountEntity> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _AccountPicker({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_AccountPicker> createState() => _AccountPickerState();
}

class _AccountPickerState extends State<_AccountPicker> {
  AccountType? _expandedType;
  int _collapseTick = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('No accounts yet'),
            TextButton(
              onPressed: () => context.push('/accounts/add'),
              child: const Text('+ Create Account'),
            ),
          ],
        ),
      );
    }

    final grouped = <AccountType, List<AccountEntity>>{};
    for (final acc in widget.accounts) {
      grouped.putIfAbsent(acc.type, () => <AccountEntity>[]).add(acc);
    }
    final selected = widget.accounts
        .where((a) => a.id == widget.selectedId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(selected.type.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${selected.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ...AccountType.values.where((t) => grouped[t] != null).map((type) {
          final items = grouped[type]!;
          return Container(
            key: ValueKey(
              '${type.name}-${_expandedType == type}-$_collapseTick',
            ),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: Text(type.icon, style: const TextStyle(fontSize: 18)),
              initiallyExpanded: _expandedType == type,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedType = expanded ? type : null;
                  _collapseTick++;
                });
              },
              title: Text(
                '${type.label} (${items.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              children: items.map((acc) {
                final isSelected = acc.id == widget.selectedId;
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.55)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      acc.type.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  title: Text(
                    acc.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${acc.type.label} • ${acc.currency}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  tileColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    widget.onSelect(acc.id);
                    setState(() {
                      _expandedType = null;
                      _collapseTick++;
                    });
                  },
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}
