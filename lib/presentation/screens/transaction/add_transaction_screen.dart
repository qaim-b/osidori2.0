import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/enums/visibility_type.dart';
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
                      duration: const Duration(milliseconds: 200),
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
            _AccountGrid(
              accounts: accounts,
              selectedId: _selectedFromAccountId,
              onSelect: (id) => setState(() => _selectedFromAccountId = id),
            ),

            // To account (transfer only)
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'To Account'),
              const SizedBox(height: 8),
              _AccountGrid(
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
              _CategoryGrid(
                categories: filteredCategories,
                selectedId: _selectedCategoryId,
                onSelect: (id) => setState(() => _selectedCategoryId = id),
              ),
            ],

            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a note (optional) ✏️',
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

class _CategoryGrid extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No categories available'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              cat.displayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccountGrid extends StatelessWidget {
  final List<AccountEntity> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _AccountGrid({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts.map((acc) {
        final isSelected = acc.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(acc.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(acc.type.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  acc.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
