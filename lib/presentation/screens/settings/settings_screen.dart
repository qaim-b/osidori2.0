import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final activePreset = ref.watch(themePresetProvider);
    final roleColors = ref.watch(roleColorsProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final activeGroupId = ref.watch(activeGroupIdProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final monthlyTxns =
        ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    final sharedTxns = monthlyTxns.where((t) => t.isShared).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final partnerTxns = sharedTxns
        .where((t) => t.ownerUserId != currentUserId)
        .toList();
    final yourTxns = sharedTxns
        .where((t) => t.ownerUserId == currentUserId)
        .toList();
    final categoryNameById = {for (final c in categories) c.id: c.shortLabel};
    final accountNameById = {
      for (final account in accounts) account.id: account.name,
    };

    final avatarProvider = avatarImageProvider(user?.avatarUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? SvgPicture.asset(
                            roleColors.mascotImage,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Guest',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickAvatar(context, ref),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Set Profile Photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).clearAvatar();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'General'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  label: 'Group Management',
                  subtitle: 'Connect partner and check sync health',
                  icon: Icons.group_rounded,
                  onTap: () => context.push('/settings/group-management'),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Group Status',
                  subtitle: 'Active group, health, shared activity',
                  icon: Icons.hub_rounded,
                  onTap: () => context.push('/settings/group-status'),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Shared Goals',
                  subtitle: 'Add and manage up to 3 goals',
                  icon: Icons.flag_circle_rounded,
                  onTap: () => context.push('/settings/goals'),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Currency',
                  subtitle:
                      ref
                          .watch(authStateProvider)
                          .valueOrNull
                          ?.preferredCurrency ??
                      AppConstants.defaultCurrency,
                  icon: Icons.currency_yen_rounded,
                  onTap: () => _pickCurrency(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppThemePreset.values.map((preset) {
                  final data = themePresetMap[preset]!;
                  return ChoiceChip(
                    label: Text(data.label),
                    selected: activePreset == preset,
                    onSelected: (_) {
                      ref.read(themePresetProvider.notifier).state = preset;
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Group Status'),
          Card(
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const ListTile(
                    leading: Icon(Icons.link_off_rounded),
                    title: Text('No linked group yet'),
                    subtitle: Text(
                      'Open Group Management and connect your partner.',
                    ),
                  );
                }
                final selectedId = activeGroupId ?? groups.first.id;
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected groups: ${groups.length}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: groups.map((g) {
                          final isActive = g.id == selectedId;
                          return ChoiceChip(
                            label: Text('${g.name} (${g.memberCount})'),
                            selected: isActive,
                            onSelected: (_) {
                              ref
                                      .read(activeGroupIdStateProvider.notifier)
                                      .state =
                                  g.id;
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      ...groups.where((g) => g.id == selectedId).map((group) {
                        final short = group.id.length > 8
                            ? group.id.substring(0, 8)
                            : group.id;
                        return Text(
                          'Active group id: $short\nMembers: ${group.memberCount}',
                          style: const TextStyle(fontSize: 12),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ListTile(title: Text('Error: $e')),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Transparency This Month'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Shared',
                          value: '${sharedTxns.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          label: 'You',
                          value: '${yourTxns.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          label: 'Partner',
                          value: '${partnerTxns.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (partnerTxns.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        'No partner transactions visible this month. If your partner already added records, run Group Repair below on both devices.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Group Repair'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_circle_outlined),
              title: const Text('Repair legacy shared records'),
              subtitle: const Text(
                'Assign your shared rows without group_id to the active group',
              ),
              trailing: FilledButton(
                onPressed: activeGroupId == null
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final userId = ref.read(currentUserIdProvider);
                          final groupId = ref.read(activeGroupIdProvider);
                          if (userId == null || groupId == null) return;

                          final txnCount = await ref
                              .read(transactionRepositoryProvider)
                              .assignUngroupedSharedToGroup(
                                userId: userId,
                                groupId: groupId,
                              );
                          final accCount = await ref
                              .read(accountRepositoryProvider)
                              .assignUngroupedSharedToGroup(
                                userId: userId,
                                groupId: groupId,
                              );

                          await ref
                              .read(monthlyTransactionsProvider.notifier)
                              .load();
                          await ref.read(accountsProvider.notifier).load();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Repair completed: $txnCount transactions, $accCount accounts updated.',
                              ),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Repair failed: $e')),
                          );
                        }
                      },
                child: const Text('Run Repair'),
              ),
            ),
          ),
          const _SectionHeader(title: 'Data'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  label: 'Export CSV',
                  subtitle: 'Download this month transactions',
                  icon: Icons.download_rounded,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final primaryColor = Theme.of(context).colorScheme.primary;
                    try {
                      final selectedMonth = ref.read(selectedMonthProvider);
                      final repo = ref.read(transactionRepositoryProvider);
                      final userId = ref.read(currentUserIdProvider);
                      if (userId == null) return;

                      final txns = await repo.getForMonth(
                        userId: userId,
                        year: selectedMonth.year,
                        month: selectedMonth.month,
                        groupIds: ref.read(groupIdsProvider),
                      );

                      final categories =
                          ref.read(categoriesProvider).valueOrNull ?? [];
                      final catNameMap = <String, String>{
                        for (final c in categories) c.id: c.shortLabel,
                      };

                      final path = await CsvExporter.exportTransactions(
                        transactions: txns,
                        categoryNames: catNameMap,
                        year: selectedMonth.year,
                        month: selectedMonth.month,
                      );
                      await CsvExporter.shareFile(path);

                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('CSV exported'),
                          backgroundColor: primaryColor,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Export error: $e')),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Manage Categories',
                  subtitle: 'Enable, disable, edit categories',
                  icon: Icons.category_rounded,
                  onTap: () => context.push('/categories'),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Manage Accounts',
                  subtitle: 'Edit or delete bank/wallet accounts',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => context.push('/accounts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Shared Activity'),
          Card(
            child: _SharedActivityList(
              sharedTxns: sharedTxns,
              accountNameById: accountNameById,
              categoryNameById: categoryNameById,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'About'),
          Card(
            child: _SettingsTile(
              label: AppConstants.appName,
              subtitle: 'v1.0.0',
              icon: Icons.info_outline_rounded,
              onTap: _showAbout(context),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('Your data stays safe in Supabase.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.expense),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.expense),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.expense),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final current = ref.read(currentCurrencyProvider);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                current == 'JPY'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: const Text('JPY (¥ Japanese Yen)'),
              onTap: () => Navigator.pop(ctx, 'JPY'),
            ),
            ListTile(
              leading: Icon(
                current == 'MYR'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: const Text('MYR (RM Malaysian Ringgit)'),
              onTap: () => Navigator.pop(ctx, 'MYR'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(authStateProvider.notifier).setPreferredCurrency(selected);
    }
  }

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1080,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final mime =
          picked.mimeType ??
          (picked.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      await ref.read(authStateProvider.notifier).setAvatar(dataUrl);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Photo update failed: $e')),
      );
    }
  }

  VoidCallback _showAbout(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, size: 28),
              const SizedBox(height: 12),
              Text(
                AppConstants.appName,
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.appTagline,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    };
  }
}

class _SharedActivityList extends StatefulWidget {
  final List<TransactionModel> sharedTxns;
  final Map<String, String> categoryNameById;
  final Map<String, String> accountNameById;

  const _SharedActivityList({
    required this.sharedTxns,
    required this.categoryNameById,
    required this.accountNameById,
  });

  @override
  State<_SharedActivityList> createState() => _SharedActivityListState();
}

class _SharedActivityListState extends State<_SharedActivityList> {
  static const int _pageSize = 3;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.sharedTxns.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.timeline_rounded),
        title: Text('No shared activity yet'),
        subtitle: Text('New shared expenses and income appear here.'),
      );
    }

    final totalPages = (widget.sharedTxns.length / _pageSize).ceil();
    final safePage = _page.clamp(0, totalPages - 1);
    if (safePage != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = safePage);
      });
    }
    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.sharedTxns.length);
    final pageItems = widget.sharedTxns.sublist(start, end);

    return Column(
      children: [
        ...pageItems.map((t) {
          final ownerShort = t.ownerUserId.length >= 6
              ? t.ownerUserId.substring(0, 6)
              : t.ownerUserId;
          final sign = t.isExpense ? '-' : '+';
          final category = t.categoryNameSnapshot?.trim().isNotEmpty == true
              ? t.categoryNameSnapshot!
              : (widget.categoryNameById[t.categoryId] ?? 'Unknown category');
          final fromAccount =
              widget.accountNameById[t.fromAccountId] ?? 'Unknown account';
          final toAccount = t.toAccountId == null
              ? null
              : (widget.accountNameById[t.toAccountId!] ?? 'Unknown account');
          final note = t.note?.trim().isNotEmpty == true ? t.note! : 'No note';
          final typeLabel =
              t.type.name[0].toUpperCase() + t.type.name.substring(1);

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        t.isExpense
                            ? Icons.south_west_rounded
                            : t.isIncome
                            ? Icons.north_east_rounded
                            : Icons.swap_horiz_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${DateFormat('MMM d, HH:mm').format(t.date)}  |  $typeLabel  |  by $ownerShort',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$sign${t.amount.toStringAsFixed(0)} ${t.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.isExpense
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _DetailChip(label: 'Category', value: category),
                      _DetailChip(label: 'From', value: fromAccount),
                      if (toAccount != null)
                        _DetailChip(label: 'To', value: toAccount),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: safePage == 0
                    ? null
                    : () => setState(() => _page = safePage - 1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Prev'),
              ),
              const Spacer(),
              Text(
                'Page ${safePage + 1} of $totalPages',
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: safePage >= totalPages - 1
                    ? null
                    : () => setState(() => _page = safePage + 1),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
