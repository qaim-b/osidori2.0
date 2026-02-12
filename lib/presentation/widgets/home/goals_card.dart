import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';

class GoalsCard extends ConsumerWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final roleColors = ref.watch(roleColorsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Shared Goals', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/settings/goals'),
                        child: const Text('Edit Goals'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('No goals yet. Add your first shared goal!'),
                ],
              );
            }

            final displayGoals = goals.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Shared Goals', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/settings/goals'),
                      child: const Text('Edit Goals'),
                    ),
                  ],
                ),
                ...displayGoals.map((goal) {
                  final progress = goal.progressPercent;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(goal.emoji.isEmpty ? '🎯' : goal.emoji),
                            const SizedBox(width: 8),
                            Expanded(child: Text(goal.name, overflow: TextOverflow.ellipsis)),
                            Text('${(progress * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progress,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(roleColors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
