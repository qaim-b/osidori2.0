import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/user_model.dart';
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
import '../../widgets/common/editorial.dart';
import '../../widgets/common/themed_backdrop.dart';
import '../../widgets/home/accounts_summary_card.dart';
import '../../widgets/home/goals_card.dart';
import '../../widgets/home/memory_timeline_section.dart';
import '../../widgets/transaction/transaction_tile.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Widget _scrollMotion({
    required Widget child,
    required double start,
    double distance = 26,
  }) {
    final progress = ((_scrollOffset - start) / 260).clamp(0.0, 1.0);
    final shift = distance * (1 - progress);
    final opacity = (0.72 + (0.28 * progress)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(offset: Offset(0, shift), child: child),
    );
  }

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
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final roleColors = ref.watch(roleColorsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final memberProfilesAsync = ref.watch(activeGroupMemberProfilesProvider);
    final memberProfiles = memberProfilesAsync.valueOrNull ?? [];
    final profilesLoading = memberProfilesAsync.isLoading;
    final youProfile = memberProfiles.where((p) => p.id == user?.id).isNotEmpty
        ? memberProfiles.where((p) => p.id == user?.id).first
        : null;
    final partnerProfile =
        memberProfiles.where((p) => p.id != user?.id).isNotEmpty
        ? memberProfiles.where((p) => p.id != user?.id).first
        : null;

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
            controller: _scrollController,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MemberAvatarBubble(
                        profile: youProfile,
                        label: youProfile?.name.isNotEmpty == true
                            ? '${youProfile!.name} (You)'
                            : 'You',
                        backgroundColor: roleColors.primary.withValues(
                          alpha: 0.16,
                        ),
                        loading: profilesLoading && youProfile == null,
                      ),
                      const SizedBox(width: 22),
                      _MemberAvatarBubble(
                        profile: partnerProfile,
                        label: partnerProfile?.name.isNotEmpty == true
                            ? partnerProfile!.name
                            : 'Partner',
                        backgroundColor: roleColors.accent.withValues(
                          alpha: 0.16,
                        ),
                        loading: profilesLoading && partnerProfile == null,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _scrollMotion(
                  start: 90,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: AppMotion.entrance,
                      curve: AppMotion.smooth,
                      builder: (context, t, child) {
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: _SummaryCards(
                        income: (totals['income'] ?? 0).toDouble(),
                        expense: (totals['expense'] ?? 0).toDouble(),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionLabel(text: 'Household Snapshot'),
              ),
              SliverToBoxAdapter(
                child: _scrollMotion(
                  start: 180,
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
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: AccountsSummaryCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: GoalsCard()),
              SliverToBoxAdapter(
                child: EditorialCard(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  accentTop: true,
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
              const SliverToBoxAdapter(child: MemoryTimelineSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/transactions/recent'),
                        child: const Text('See all'),
                      ),
                    ],
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

                  final displayTxns = txns.take(7).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final txn = displayTxns[index];
                      return EditorialCard(
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

class _MemberAvatarBubble extends StatelessWidget {
  final UserModel? profile;
  final String label;
  final Color backgroundColor;
  final bool loading;

  const _MemberAvatarBubble({
    required this.profile,
    required this.label,
    required this.backgroundColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final avatarProvider = avatarImageProvider(avatarUrl);
    final expectsAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final showLoadingOnly = loading || (expectsAvatar && avatarProvider == null);

    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: backgroundColor,
          backgroundImage: avatarProvider,
          child: avatarProvider != null
              ? null
              : showLoadingOnly
              ? const Icon(Icons.person_rounded, size: 28, color: Colors.white)
              : const Icon(Icons.person_rounded, size: 28, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double income;
  final double expense;

  const _SummaryCards({required this.income, required this.expense});

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
            child: DisplayNumber(
              value: CurrencyFormatter.format(amount),
              color: color,
              size: 22,
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
