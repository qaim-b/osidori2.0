import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/account_provider.dart';

class AccountsSummaryCard extends ConsumerWidget {
  const AccountsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: accountsAsync.when(
          data: (accounts) {
            final total = accounts.fold<double>(0, (sum, a) => sum + a.initialBalance);
            final top = [...accounts]..sort((a, b) => b.initialBalance.compareTo(a.initialBalance));
            final topAccounts = top.take(3).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/accounts'),
                      child: const Text('See All >'),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (topAccounts.isEmpty)
                  const Text('No accounts yet')
                else
                  ...topAccounts.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(a.type.icon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(a.initialBalance),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
      ),
    );
  }
}
