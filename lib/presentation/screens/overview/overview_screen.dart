import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/common/animated_mascot.dart';
import '../../widgets/common/themed_backdrop.dart';
import '../../widgets/home/accounts_summary_card.dart';
import '../../widgets/home/goals_card.dart';
import '../../widgets/home/memory_timeline_section.dart';
import '../../widgets/transaction/transaction_tile.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(monthlyTransactionsProvider.notifier).load(),
      ref.read(accountsProvider.notifier).load(),
      ref.read(categoriesProvider.notifier).load(),
      ref.read(goalsProvider.notifier).load(),
      ref.read(budgetLimitsProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final roleColors = ref.watch(roleColorsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final memberProfiles =
        ref.watch(activeGroupMemberProfilesProvider).valueOrNull ?? [];
    final myAvatarProvider = avatarImageProvider(user?.avatarUrl);

    final catMap = <String, String>{};
    final catEntityMap = <String, CategoryEntity>{};
    for (final cat in categories.valueOrNull ?? <CategoryEntity>[]) {
      catMap[cat.id] = cat.shortLabel;
      catEntityMap[cat.id] = cat;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemedBackdrop(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: roleColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            backgroundImage: myAvatarProvider,
                            child: myAvatarProvider == null
                                ? roleColors.mascotImage.endsWith('.svg')
                                      ? SvgPicture.asset(
                                          roleColors.mascotImage,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.asset(
                                          roleColors.mascotImage,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                        )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, ${user?.name ?? 'there'}!',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                selectedMonth.monthYear,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: roleColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          backgroundImage: myAvatarProvider,
                          child: myAvatarProvider == null
                              ? SvgPicture.asset(
                                  roleColors.mascotImage,
                                  width: 14,
                                  height: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        onPressed: () {
                          ref
                              .read(selectedMonthProvider.notifier)
                              .state = DateTime(
                            selectedMonth.year,
                            selectedMonth.month - 1,
                            1,
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state =
                              DateTime(now.year, now.month, 1);
                        },
                        child: Text(
                          selectedMonth.monthYear,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 28),
                        onPressed: () {
                          ref
                              .read(selectedMonthProvider.notifier)
                              .state = DateTime(
                            selectedMonth.year,
                            selectedMonth.month + 1,
                            1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (memberProfiles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: memberProfiles.take(2).map((profile) {
                        final profileRole = profile.role ?? 'stitch';
                        final fallbackAsset = profileRole == 'angel'
                            ? 'assets/images/angel.svg'
                            : (profileRole == 'solo'
                                  ? 'assets/images/stitchangel.svg'
                                  : 'assets/images/stitch.svg');
                        final provider = avatarImageProvider(profile.avatarUrl);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: roleColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                backgroundImage: provider,
                                child: provider == null
                                    ? SvgPicture.asset(
                                        fallbackAsset,
                                        width: 18,
                                        height: 18,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile.id == user?.id ? 'You' : 'Partner',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SummaryCards(
                    income: (totals['income'] ?? 0).toDouble(),
                    expense: (totals['expense'] ?? 0).toDouble(),
                    net: (totals['net'] ?? 0).toDouble(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.remove_circle_outline_rounded,
                          label: 'Add Expense',
                          onTap: () => context.push('/add'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add Income',
                          onTap: () => context.push('/add'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.tune_rounded,
                          label: 'Budgets',
                          onTap: () => context.push('/summary/set-budget'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: AccountsSummaryCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: GoalsCard()),
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Breakdown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final total = categoryTotals.values.fold<double>(
                              0,
                              (sum, v) => sum + v,
                            );
                            return CategoryDonutChart(
                              categoryTotals: categoryTotals,
                              categoryNames: catMap,
                              currency: 'JPY',
                              totalAmount: total,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: MemoryTimelineSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              transactions.when(
                data: (txns) {
                  if (txns.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            AnimatedMascot(
                              imagePath: roleColors.mascotImage,
                              size: 60,
                              glowColor: roleColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions this month',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to add your first one!',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final displayTxns = txns.take(20).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final txn = displayTxns[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 3,
                        ),
                        child: TransactionTile(
                          transaction: txn,
                          category: catEntityMap[txn.categoryId],
                        ),
                      );
                    }, childCount: displayTxns.length),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _SummaryCards({
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'Income',
            amount: income,
            color: AppColors.income,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: 'Expense',
            amount: expense,
            color: AppColors.expense,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: 'Net',
            amount: net,
            color: net >= 0 ? AppColors.income : AppColors.expense,
            icon: net >= 0 ? Icons.trending_up : Icons.trending_down,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _MiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
