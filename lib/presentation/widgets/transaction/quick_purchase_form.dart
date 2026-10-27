import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/quick_categories.dart';
import '../../../core/utils/purchase_amount.dart';
import '../../../domain/entities/category_entity.dart';

class QuickPurchaseForm extends StatelessWidget {
  final List<CategoryEntity> categories;
  final List<String> recentIds;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final DateTime date;
  final String currency;
  final VoidCallback onDate;
  final VoidCallback onCurrency;
  final VoidCallback onSave;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onAdvanced;
  final VoidCallback onClose;
  final VoidCallback onRetryCategories;
  final VoidCallback onCreateAccount;
  final bool loading;
  final bool categoryError;
  final bool accountLoading;
  final bool hasAccount;
  final bool saving;
  final bool scanning;
  final bool categoryLocked;
  final bool receiptScanningEnabled;
  final Uint8List? receiptImage;
  final String? receiptMessage;

  const QuickPurchaseForm({
    super.key,
    required this.categories,
    required this.recentIds,
    required this.selectedId,
    required this.onSelect,
    required this.amountController,
    required this.noteController,
    required this.date,
    required this.currency,
    required this.onDate,
    required this.onCurrency,
    required this.onSave,
    required this.onCamera,
    required this.onGallery,
    required this.onAdvanced,
    required this.onClose,
    required this.onRetryCategories,
    required this.onCreateAccount,
    required this.loading,
    required this.categoryError,
    required this.accountLoading,
    required this.hasAccount,
    required this.saving,
    required this.scanning,
    this.categoryLocked = false,
    this.receiptScanningEnabled = false,
    this.receiptImage,
    this.receiptMessage,
  });

  Future<void> _allCategories(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) =>
          _CategorySearch(categories: categories, selectedId: selectedId),
    );
    if (context.mounted && chosen != null) onSelect(chosen);
  }

  void _key(String key) {
    final old = amountController.text;
    String next;
    if (key == 'back') {
      next = old.isEmpty ? '' : old.substring(0, old.length - 1);
    } else if (key == '.') {
      if (old.contains('.')) return;
      next = old.isEmpty ? '0.' : '$old.';
    } else {
      next = old == '0' ? key : '$old$key';
      if (next.contains('.') && next.split('.').last.length > 2) return;
      if (next.length > 12) return;
    }
    amountController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = categories.where((c) => c.id == selectedId).firstOrNull;
    final busy = saving || scanning;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add purchase'),
          leading: IconButton(
            tooltip: 'Close',
            onPressed: busy ? null : onClose,
            icon: const Icon(Icons.close),
          ),
          actions: [
            if (selected == null || !receiptScanningEnabled)
              TextButton(
                onPressed: busy ? null : onAdvanced,
                child: const Text('More options'),
              )
            else
              PopupMenuButton<String>(
                enabled: !busy,
                tooltip: 'More options',
                onSelected: (value) {
                  if (value == 'camera') onCamera();
                  if (value == 'gallery') onGallery();
                  if (value == 'advanced') onAdvanced();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'camera', child: Text('Scan receipt')),
                  PopupMenuItem(
                    value: 'gallery',
                    child: Text('Choose receipt photo'),
                  ),
                  PopupMenuItem(
                    value: 'advanced',
                    child: Text('Income, transfer & more'),
                  ),
                ],
              ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: busy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (selected == null && receiptScanningEnabled)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCamera,
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Scan receipt'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Choose receipt photo',
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                  ],
                ),
              if (scanning) ...[
                const LinearProgressIndicator(),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Reading total, date, store and category…'),
                ),
              ],
              if (receiptMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (receiptImage != null) ...[
                          Image.memory(
                            receiptImage!,
                            width: 48,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: Text(receiptMessage!)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (categoryError) ...[
                const Text('Could not load your categories.'),
                TextButton(
                  onPressed: onRetryCategories,
                  child: const Text('Try again'),
                ),
              ] else if (categories.isEmpty)
                const Text(
                  'No expense categories are enabled. Enable a category in Settings → Categories.',
                ),
              if (selected == null && categories.isNotEmpty) ...[
                Text(
                  'What did you buy?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recent categories first. Tap one to enter the amount.',
                ),
                const SizedBox(height: 16),
                _CategoryGrid(
                  categories: quickCategories(categories, recentIds),
                  selectedId: selectedId,
                  onSelect: onSelect,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _allCategories(context),
                  icon: const Icon(Icons.search),
                  label: const Text('All categories · search or scroll'),
                ),
              ],
              if (selected != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    selected.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(selected.name),
                  subtitle: Text(
                    categoryLocked
                        ? 'Travel Mode category'
                        : 'Category ${selected.displayNumber}',
                  ),
                  trailing: categoryLocked
                      ? const Icon(Icons.lock_outline)
                      : const Icon(Icons.expand_more),
                  onTap: categoryLocked ? null : () => _allCategories(context),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: amountController,
                  builder: (context, value, _) => Semantics(
                    label: 'Purchase amount in $currency',
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${CurrencyFormatter.symbolFor(currency)} ${value.text.isEmpty ? '0' : value.text}',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('EEE, MMM d').format(date)),
                      onPressed: onDate,
                    ),
                    ActionChip(label: Text(currency), onPressed: onCurrency),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  textInputAction: TextInputAction.done,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Store / note (optional)',
                    hintText: 'e.g. OK Store',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
              ],
              if (!accountLoading && !hasAccount) ...[
                const SizedBox(height: 12),
                const Text(
                  'Add a payment account before saving your first purchase.',
                ),
                TextButton(
                  onPressed: onCreateAccount,
                  child: const Text('Add account'),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: selected == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    8 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (MediaQuery.viewInsetsOf(context).bottom == 0)
                        for (final row in [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          [currency == 'JPY' ? '00' : '.', '0', 'back'],
                        ])
                          Row(
                            children: row
                                .map(
                                  (key) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: SizedBox(
                                        height: 52,
                                        child: FilledButton.tonal(
                                          style: FilledButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onPressed: busy
                                              ? null
                                              : () => _key(key),
                                          child: key == 'back'
                                              ? const Icon(
                                                  Icons.backspace_outlined,
                                                  semanticLabel:
                                                      'Delete last digit',
                                                )
                                              : Text(key),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: amountController,
                        builder: (context, value, _) {
                          final amount = double.tryParse(value.text);
                          final canSave =
                              !busy &&
                              hasAccount &&
                              !accountLoading &&
                              isValidPurchaseAmount(amount, currency);
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: canSave ? onSave : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      isValidPurchaseAmount(amount, currency)
                                          ? 'Save ${CurrencyFormatter.format(amount!, currency: currency)}'
                                          : (amount != null && amount > 0
                                                ? 'Check amount or currency'
                                                : 'Enter amount'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 600
          ? 6
          : constraints.maxWidth < 280
          ? 2
          : 3;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 118,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final colors = Theme.of(context).colorScheme;
          return Material(
            color: category.id == selectedId
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => onSelect(category.id),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _CategorySearch extends StatefulWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  const _CategorySearch({required this.categories, required this.selectedId});
  @override
  State<_CategorySearch> createState() => _CategorySearchState();
}

class _CategorySearchState extends State<_CategorySearch> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.categories
        .where(
          (c) =>
              c.name.toLowerCase().contains(_query) ||
              c.displayNumber.toString().contains(_query) ||
              c.emoji.contains(_query),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Text(
              'All categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search name or category number',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching categories'))
                  : ListView(
                      children: [
                        _CategoryGrid(
                          categories: filtered,
                          selectedId: widget.selectedId,
                          onSelect: (id) => Navigator.of(context).pop(id),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
