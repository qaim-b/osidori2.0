import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_limit_provider.dart';
import '../../providers/bill_reminder_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/recurring_rule_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/common/animated_mascot.dart';
import '../../widgets/common/editorial.dart';
import '../../widgets/common/themed_backdrop.dart';
import '../../widgets/home/accounts_summary_card.dart';
import '../../widgets/home/bill_reminders_card.dart';
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
  UserModel? _cachedYouProfile;
  UserModel? _cachedPartnerProfile;
  String? _lastReminderSignal;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() async {
      await ref.read(recurringRulesProvider.notifier).generateCatchUp();
      await ref.read(billRemindersProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Keep listener for pull-to-refresh glow behavior without rebuilding on scroll.
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
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final roleColors = ref.watch(roleColorsProvider);
    final upcomingReminders = ref.watch(upcomingBillRemindersProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final memberProfilesAsync = ref.watch(activeGroupMemberProfilesProvider);
    final memberProfiles = memberProfilesAsync.valueOrNull ?? [];
    final liveYouProfile =
        memberProfiles.where((p) => p.id == user?.id).isNotEmpty
        ? memberProfiles.where((p) => p.id == user?.id).first
        : null;
    final livePartnerProfile =
        memberProfiles.where((p) => p.id != user?.id).isNotEmpty
        ? memberProfiles.where((p) => p.id != user?.id).first
        : null;
    final youProfile = liveYouProfile ?? _cachedYouProfile;
    final partnerProfile = livePartnerProfile ?? _cachedPartnerProfile;
    if (liveYouProfile != null) _cachedYouProfile = liveYouProfile;
    if (livePartnerProfile != null) _cachedPartnerProfile = livePartnerProfile;

    final catMap = <String, String>{};
    final catEntityMap = <String, CategoryEntity>{};
    final snapshotNameById = <String, String>{};
    final snapshotEmojiById = <String, String>{};
    for (final cat in categories.valueOrNull ?? <CategoryEntity>[]) {
      catMap[cat.id] = cat.shortLabel;
      catEntityMap[cat.id] = cat;
    }
    for (final txn in transactions.valueOrNull ?? const []) {
      if (txn.categoryNameSnapshot != null &&
          txn.categoryNameSnapshot!.trim().isNotEmpty) {
        snapshotNameById[txn.categoryId] = txn.categoryNameSnapshot!;
      }
      if (txn.categoryEmojiSnapshot != null &&
          txn.categoryEmojiSnapshot!.trim().isNotEmpty) {
        snapshotEmojiById[txn.categoryId] = txn.categoryEmojiSnapshot!;
      }
    }
    final breakdownTotals = <String, double>{};
    final breakdownNames = <String, String>{};
    for (final txn in transactions.valueOrNull ?? const []) {
      if (!txn.isExpense) continue;
      final cat = catEntityMap[txn.categoryId];
      final resolvedName =
          cat?.name ??
          snapshotNameById[txn.categoryId] ??
          (txn.categoryDisplayNumberSnapshot != null
              ? 'Category #${txn.categoryDisplayNumberSnapshot}'
              : 'Other');
      final resolvedEmoji =
          cat?.emoji ?? snapshotEmojiById[txn.categoryId] ?? '📦';
      final key = '$resolvedEmoji $resolvedName';
      breakdownTotals[key] = (breakdownTotals[key] ?? 0) + txn.amount;
      breakdownNames[key] = key;
    }

    final urgent = upcomingReminders
        .where((r) => r.reminder.isActive && r.daysLeft <= 0)
        .toList();
    if (urgent.isNotEmpty) {
      final signal = urgent
          .map((e) => '${e.reminder.id}:${e.daysLeft}')
          .join('|');
      if (_lastReminderSignal != signal) {
        _lastReminderSignal = signal;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                urgent.length == 1
                    ? 'Reminder: ${urgent.first.reminder.title} is due ${urgent.first.daysLeft < 0 ? 'and overdue' : 'today'}.'
                    : '${urgent.length} reminders are due or overdue.',
              ),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => context.push('/settings/automation'),
              ),
            ),
          );
        });
      }
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
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SummaryCards(
                    income: (totals['income'] ?? 0).toDouble(),
                    expense: (totals['expense'] ?? 0).toDouble(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Text(
                    'Household Snapshot',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: BillRemindersCard()),
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
                          final total = breakdownTotals.values.fold<double>(
                            0,
                            (sum, v) => sum + v,
                          );
                          return CategoryDonutChart(
                            categoryTotals: breakdownTotals,
                            categoryNames: breakdownNames,
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

  const _MemberAvatarBubble({
    required this.profile,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final avatarProvider = avatarImageProvider(avatarUrl);

    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: backgroundColor,
          backgroundImage: avatarProvider,
          child: avatarProvider != null
              ? null
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
