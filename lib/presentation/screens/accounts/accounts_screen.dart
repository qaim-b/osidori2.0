import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/credit_card_cycle.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/enums/account_type.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final cycleTxns =
        ref.watch(creditCycleTransactionsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/accounts/add'),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No accounts yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first account to start tracking',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/accounts/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _AccountCard(account: account, cycleTxns: cycleTxns);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final AccountModel account;
  final List<TransactionModel> cycleTxns;

  const _AccountCard({required this.account, required this.cycleTxns});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(context, ref, account),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      account.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.angelPink.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Shared',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              account.type.label,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(
                          account.initialBalance,
                          currency: account.currency,
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditDialog(context, ref, account);
                          }
                          if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete account?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref
                                  .read(accountsProvider.notifier)
                                  .deleteAccount(account.id);
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                ],
              ),
              if (account.type == AccountType.credit)
                _CreditCycleGuide(account: account, txns: cycleTxns),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    AccountModel current,
  ) async {
    final nameController = TextEditingController(text: current.name);
    final balanceController = TextEditingController(
      text: current.initialBalance.toStringAsFixed(0),
    );
    int cycleStart = current.creditCycleStartDay ?? 27;
    int paymentDay = current.creditPaymentDay ?? 27;
    AccountType type = current.type;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Edit Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Balance'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AccountType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: AccountType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.icon} ${t.label}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => type = value);
                    }
                  },
                ),
                if (type == AccountType.credit) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: cycleStart,
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
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => cycleStart = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: paymentDay,
                          decoration: const InputDecoration(
                            labelText: 'Pay day',
                          ),
                          items: List.generate(31, (i) => i + 1)
                              .map(
                                (d) => DropdownMenuItem<int>(
                                  value: d,
                                  child: Text('$d'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => paymentDay = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (save == true) {
      final parsedBalance = double.tryParse(balanceController.text.trim()) ?? 0;
      final updated = AccountModel(
        id: current.id,
        name: nameController.text.trim().isEmpty
            ? current.name
            : nameController.text.trim(),
        type: type,
        ownerScope: current.ownerScope,
        ownerUserId: current.ownerUserId,
        groupId: current.groupId,
        currency: current.currency,
        initialBalance: parsedBalance,
        creditCycleStartDay: type == AccountType.credit ? cycleStart : null,
        creditPaymentDay: type == AccountType.credit ? paymentDay : null,
        createdAt: current.createdAt,
      );
      await ref.read(accountsProvider.notifier).updateAccount(updated);
    }
  }
}

class _CreditCycleGuide extends StatelessWidget {
  final AccountModel account;
  final List<TransactionModel> txns;

  const _CreditCycleGuide({required this.account, required this.txns});

  @override
  Widget build(BuildContext context) {
    final snapshot = CreditCardCycle.buildSnapshot(
      account: account,
      transactions: txns,
    );
    if (snapshot == null) return const SizedBox.shrink();
    final dateFmt = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing Cycle Helper',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Last statement: ${dateFmt.format(snapshot.lastStatementStart)} - ${dateFmt.format(snapshot.lastStatementEnd)}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            'Last statement amount: ${CurrencyFormatter.format(snapshot.lastStatementAmount, currency: account.currency)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Current cycle: ${dateFmt.format(snapshot.currentCycleStart)} - ${dateFmt.format(snapshot.currentCycleEnd)}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            'Current cycle spend: ${CurrencyFormatter.format(snapshot.currentCycleAmount, currency: account.currency)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Next payment date: ${dateFmt.format(snapshot.nextPaymentDate)}',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
