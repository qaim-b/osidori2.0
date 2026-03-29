import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/fx_converter.dart';
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
import '../../providers/travel_mode_provider.dart';

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
  String _entryCurrency = 'JPY';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entryCurrency = ref.read(currentCurrencyProvider);
  }

  void _appendDoubleZero() {
    final text = _amountController.text;
    if (text.isEmpty || text.contains('.')) return;

    final selection = _amountController.selection;
    if (!selection.isValid) {
      _amountController.text = '${_amountController.text}00';
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
      return;
    }

    final newText = text.replaceRange(selection.start, selection.end, '00');
    final newOffset = selection.start + 2;
    _amountController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _syncHiddenAccountSelection(List<AccountEntity> accounts) {
    if (accounts.isEmpty) return;

    final firstAccountId = accounts.first.id;
    final fallbackToId = accounts
        .where((a) => a.id != (_selectedFromAccountId ?? firstAccountId))
        .map((a) => a.id)
        .firstOrNull;

    if (_type == TransactionType.transfer) {
      if (_selectedFromAccountId == null ||
          !accounts.any((a) => a.id == _selectedFromAccountId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedFromAccountId = firstAccountId);
        });
      }
      if (fallbackToId != null &&
          (_selectedToAccountId == null ||
              _selectedToAccountId == _selectedFromAccountId ||
              !accounts.any((a) => a.id == _selectedToAccountId))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedToAccountId = fallbackToId);
        });
      }
      return;
    }

    if (_selectedFromAccountId == null ||
        !accounts.any((a) => a.id == _selectedFromAccountId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedFromAccountId = firstAccountId);
      });
    }
  }

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

  Future<void> _pickEntryCurrency(String appCurrency) async {
    const options = <({String code, String label, String symbol, String vibe})>[
      (
        code: 'JPY',
        label: 'Japanese Yen',
        symbol: '\u00A5',
        vibe: 'Japan money',
      ),
      (
        code: 'MYR',
        label: 'Malaysian Ringgit',
        symbol: 'RM',
        vibe: 'Malaysia money',
      ),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.surfaceVariant.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose entry currency',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your main currency stays ${appCurrency.toUpperCase()}, but each entry can keep its original currency.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map((option) {
                  final isSelected = _entryCurrency == option.code;
                  final accent = option.code == 'JPY'
                      ? AppColors.primary
                      : AppColors.secondary;
                  return AnimatedContainer(
                    duration: AppMotion.normal,
                    curve: AppMotion.smooth,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: isSelected ? 0.18 : 0.08),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: isSelected ? 0.52 : 0.16,
                        ),
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(sheetContext).pop(option.code),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                option.symbol,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.code,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    option.vibe,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_outward_rounded,
                              color: accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _entryCurrency = selected);
    }
  }

  Widget _buildFxPreview({
    required String appCurrency,
    required String previewCurrency,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _amountController,
      builder: (context, value, _) {
        final amount = double.tryParse(value.text);
        if (amount == null || amount <= 0) {
          return AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.smooth,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              'Enter an amount to preview how it lands in $previewCurrency.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return FutureBuilder<
          ({double rate, double converted, DateTime quotedAt, bool isFallback})
        >(
          future: () async {
            final quote = await FxConverter.getQuote(
              fromCurrency: _entryCurrency,
              toCurrency: previewCurrency,
              forDate: _date,
            );
            return (
              rate: quote.rate,
              converted: amount * quote.rate,
              quotedAt: quote.quotedAt,
              isFallback: quote.isFallback,
            );
          }(),
          builder: (context, snapshot) {
            final converted = snapshot.data?.converted;
            final rate = snapshot.data?.rate;
            final quotedAt = snapshot.data?.quotedAt;
            final isFallback = snapshot.data?.isFallback ?? false;
            final accent = previewCurrency == appCurrency.toUpperCase()
                ? AppColors.primary
                : AppColors.secondary;

            return AnimatedSwitcher(
              duration: AppMotion.reveal,
              switchInCurve: AppMotion.smooth,
              switchOutCurve: AppMotion.dismiss,
              child: Container(
                key: ValueKey(
                  '${_entryCurrency}_${value.text}_$previewCurrency',
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            previewCurrency == appCurrency.toUpperCase()
                                ? 'Main Amount'
                                : 'Rate Preview',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              letterSpacing: 0.7,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_entryCurrency.toUpperCase()} -> $previewCurrency',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      converted == null
                          ? 'Converting...'
                          : CurrencyFormatter.format(
                              converted,
                              currency: previewCurrency,
                            ),
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      converted == null
                          ? 'Pulling the latest available rate'
                          : 'At ${CurrencyFormatter.format(amount, currency: _entryCurrency)}, the rate on ${DateFormat('MMMM d, yyyy').format(quotedAt ?? _date)} gives about ${CurrencyFormatter.format(converted, currency: previewCurrency)}.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (rate != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.66),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '1 ${_entryCurrency.toUpperCase()} = ${rate.toStringAsFixed(4)} $previewCurrency on ${DateFormat('MMMM d, yyyy').format(quotedAt ?? _date)}${isFallback ? ' (cached)' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account is available for saving yet')),
      );
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
      final appCurrency = ref.read(currentCurrencyProvider).toUpperCase();
      final entryCurrency = _entryCurrency.toUpperCase();
      final fxQuote = await FxConverter.getQuote(
        fromCurrency: entryCurrency,
        toCurrency: appCurrency,
        forDate: _date,
      );
      final lockedBase = amount * fxQuote.rate;

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
            currency: entryCurrency,
            originalAmount: amount,
            originalCurrency: entryCurrency,
            fxRateToBase: fxQuote.rate,
            fxBaseCurrency: appCurrency,
            baseAmountLocked: lockedBase,
            fxRateDate: fxQuote.quotedAt,
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
                const Text(''),
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
    final appCurrency = ref.watch(currentCurrencyProvider);
    final counterCurrency = _entryCurrency.toUpperCase() == 'JPY'
        ? 'MYR'
        : 'JPY';
    final previewCurrency =
        _entryCurrency.toUpperCase() == appCurrency.toUpperCase()
        ? counterCurrency
        : appCurrency.toUpperCase();
    final travelMode = ref.watch(travelModeProvider);

    final categories = categoriesAsync.valueOrNull ?? [];
    final accounts = accountsAsync.valueOrNull ?? [];
    _syncHiddenAccountSelection(accounts);
    final honeymoonCategory = findHoneymoonCategory(categories);
    final travelModeActive =
        travelMode.enabled &&
        _type == TransactionType.expense &&
        honeymoonCategory != null;
    if (travelModeActive && _selectedCategoryId != honeymoonCategory.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedCategoryId = honeymoonCategory.id);
      });
    }

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
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    AppColors.surfaceVariant.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      CurrencyFormatter.symbolFor(_entryCurrency),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
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
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                      color: AppColors.textPrimary,
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
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _pickEntryCurrency(appCurrency),
                        icon: const Icon(Icons.currency_exchange_rounded),
                        label: Text('Entry: $_entryCurrency'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Text(
                          'Main currency: ${appCurrency.toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildFxPreview(
                    appCurrency: appCurrency,
                    previewCurrency: previewCurrency,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: _appendDoubleZero,
                      child: const Text('00'),
                    ),
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

            if (_type == TransactionType.transfer) ...[
              _SectionLabel(label: 'From Account'),
              const SizedBox(height: 8),
              _AccountPicker(
                accounts: accounts,
                selectedId: _selectedFromAccountId,
                onSelect: (id) => setState(() => _selectedFromAccountId = id),
              ),
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
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: const Text(
                  'Account selection is hidden for now, so you can log this month more quickly.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],

            // Category selector (not for transfers)
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 16),
              if (travelMode.enabled && honeymoonCategory == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'Travel Mode is on, but no Honeymoon category was found. Create it in Categories to lock travel expenses.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _SectionLabel(
                label: travelModeActive
                    ? 'Travel Mode Category'
                    : '${_type == TransactionType.expense ? 'Expense' : 'Income'} Category',
              ),
              const SizedBox(height: 8),
              if (travelModeActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          honeymoonCategory.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${honeymoonCategory.displayLabel} (locked)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                )
              else ...[
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
            ],

            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    "Add a Note (Optional, let's help each other understand each item more)",
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
                              'Save Transaction',
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
                    '${acc.type.label} -  ${acc.currency}',
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
