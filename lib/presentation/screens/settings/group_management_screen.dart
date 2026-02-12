import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  final _partnerCodeController = TextEditingController();
  final _groupNameController = TextEditingController(text: 'Our Shared Space');
  bool _connecting = false;

  @override
  void dispose() {
    _partnerCodeController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final groups = ref.watch(groupsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Group Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Partner Code',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: SelectableText(userId ?? '-')),
                        IconButton(
                          onPressed: userId == null
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  await Clipboard.setData(
                                    ClipboardData(text: userId),
                                  );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Code copied'),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _partnerCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Partner code (UUID)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(labelText: 'Group name'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _connecting
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _connecting = true);
                              try {
                                final groupId = await ref
                                    .read(groupsProvider.notifier)
                                    .createCoupleGroup(
                                      partnerUserId:
                                          _partnerCodeController.text,
                                      name: _groupNameController.text,
                                    );
                                if (groupId != null) {
                                  ref
                                          .read(
                                            activeGroupIdStateProvider.notifier,
                                          )
                                          .state =
                                      groupId;
                                }
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Connected successfully'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to connect: $e'),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _connecting = false);
                                }
                              }
                            },
                      child: _connecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect Partner'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_2_rounded),
              title: Text('Connected groups: ${groups.length}'),
              subtitle: const Text(
                'Use Group Status page for details and sync health',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
