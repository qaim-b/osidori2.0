import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../providers/auth_provider.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionEntity transaction;
  final CategoryEntity? category;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;

    final amountColor = isTransfer
        ? AppColors.transfer
        : (isExpense ? AppColors.expense : AppColors.income);
    final sign = isExpense ? '-' : (isTransfer ? '' : '+');

    final currentUserId = ref.watch(currentUserIdProvider);
    final isMine = currentUserId != null && transaction.ownerUserId == currentUserId;
    final ownerLabel = isMine
        ? 'You'
        : 'Partner ${transaction.ownerUserId.substring(0, 6)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                category?.emoji ?? '📋',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: transaction.isShared
                              ? AppColors.angelPink.withValues(alpha: 0.15)
                              : AppColors.stitchBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.isShared ? 'Shared' : 'Personal',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ownerLabel,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transaction.date.shortDate,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                      if (transaction.note != null &&
                          transaction.note!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            transaction.note!,
                            style:
                                const TextStyle(fontSize: 11, color: AppColors.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(transaction.amount, currency: transaction.currency)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
