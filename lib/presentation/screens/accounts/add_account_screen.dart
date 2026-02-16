import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/account_type.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_text_field.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _type = AccountType.bank;
  int _cycleStartDay = 27;
  int _paymentDay = 27;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an account name')));
      return;
    }

    setState(() => _saving = true);
    final appCurrency = ref.read(currentCurrencyProvider);

    try {
      await ref
          .read(accountsProvider.notifier)
          .addAccount(
            name: _nameController.text.trim(),
            type: _type,
            // All accounts are shared by default for couple transparency.
            currency: appCurrency,
            initialBalance: double.tryParse(_balanceController.text) ?? 0,
            creditCycleStartDay: _type == AccountType.credit
                ? _cycleStartDay
                : null,
            creditPaymentDay: _type == AccountType.credit ? _paymentDay : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created'),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _nameController,
              hintText: 'Account name (e.g., Cash Wallet)',
              prefixIcon: Icons.label_outline,
            ),
            const SizedBox(height: 20),
            Text('Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccountType.values.map((type) {
                final isSelected = _type == type;
                return GestureDetector(
                  onTap: () => setState(() => _type = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(type.label),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _balanceController,
              hintText: 'Initial balance (optional)',
              prefixIcon: Icons.account_balance_wallet,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            if (_type == AccountType.credit) ...[
              const SizedBox(height: 20),
              Text(
                'Credit Card Billing Cycle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _cycleStartDay,
                      decoration: const InputDecoration(
                        labelText: 'Cycle starts',
                      ),
                      items: List.generate(31, (i) => i + 1)
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _cycleStartDay = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _paymentDay,
                      decoration: const InputDecoration(labelText: 'Pay day'),
                      items: List.generate(31, (i) => i + 1)
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _paymentDay = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Example: Start 27 means each statement runs 27 -> 26 of next month.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Create Shared Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
