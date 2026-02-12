import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transaction_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final activePreset = ref.watch(themePresetProvider);
    final groupsAsync = ref.watch(groupsProvider);

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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.dreamyGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '*',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Guest',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
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
                  subtitle: 'Connect your partner account',
                  emoji: '👥',
                  onTap: () => _showGroupManagement(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Currency',
                  subtitle: AppConstants.defaultCurrency,
                  emoji: '💱',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Multi-currency support coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  label: 'Shared Goals',
                  subtitle: 'Add and manage up to 3 goals',
                  emoji: '🎯',
                  onTap: () => context.push('/settings/goals'),
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
                    leading: Text('🔗'),
                    title: Text('No linked group yet'),
                    subtitle:
                        Text('Open Group Management to connect with your partner'),
                  );
                }
                final group = groups.first;
                return ListTile(
                  leading: const Text('👥'),
                  title: Text(group.name),
                  subtitle: Text(
                    'Members: ${group.memberCount} | ID: ${group.id.substring(0, 8)}...',
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
          const _SectionHeader(title: 'Data'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  label: 'Export CSV',
                  subtitle: 'Download this month\'s transactions',
                  emoji: '📊',
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
                      );

                      final path = await CsvExporter.exportTransactions(
                        transactions: txns,
                        categoryNames: const {},
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
                  subtitle: 'Enable/disable, edit categories',
                  emoji: '🗂',
                  onTap: () => context.push('/categories'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'About'),
          Card(
            child: _SettingsTile(
              label: AppConstants.appName,
              subtitle: 'v1.0.0',
              emoji: '⭐',
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
              label: const Text('Sign Out',
                  style: TextStyle(color: AppColors.expense)),
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

  Future<void> _showGroupManagement(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserIdProvider);
    final partnerCodeController = TextEditingController();
    final groupNameController = TextEditingController(text: 'Our Shared Space');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Group Management'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this code with your partner:'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      userId ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: userId == null
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: userId));
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: partnerCodeController,
                decoration: const InputDecoration(
                  labelText: 'Partner Code (their user ID)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: groupNameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(groupsProvider.notifier).createCoupleGroup(
                        partnerUserId: partnerCodeController.text,
                        name: groupNameController.text,
                      );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to connect: $e')),
                  );
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  VoidCallback _showAbout(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('* * *', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 12),
              Text(AppConstants.appName,
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(AppConstants.appTagline,
                  style: Theme.of(ctx).textTheme.bodyMedium),
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
  final String emoji;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
