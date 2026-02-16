import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/goal_model.dart';
import '../../providers/goal_provider.dart';

class ManageGoalsScreen extends ConsumerWidget {
  const ManageGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Goals')),
      body: goalsAsync.when(
        data: (goals) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...goals.map((goal) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      goal.emoji.isEmpty ? '🎯' : goal.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: Text(goal.name),
                    subtitle: Text(
                      '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _showEditGoalDialog(context, ref, goal),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.expense,
                          ),
                          onPressed: () => ref
                              .read(goalsProvider.notifier)
                              .deleteGoal(goal.id),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              if (goals.length < 3)
                FilledButton.icon(
                  onPressed: () => _showAddGoalDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Goal'),
                )
              else
                const Text('Maximum 3 goals reached'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    GoalModel goal,
  ) async {
    final emojiController = TextEditingController(
      text: goal.emoji.isEmpty ? '🎯' : goal.emoji,
    );
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(
      text: goal.targetAmount.toStringAsFixed(0),
    );
    final currentController = TextEditingController(
      text: goal.currentAmount.toStringAsFixed(0),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Target Amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Current Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      final name = nameController.text.trim();
      final target = double.tryParse(targetController.text.trim()) ?? 0;
      final current = double.tryParse(currentController.text.trim()) ?? 0;
      if (name.isEmpty || target <= 0) return;

      await ref
          .read(goalsProvider.notifier)
          .updateGoal(
            GoalModel(
              id: goal.id,
              userId: goal.userId,
              groupId: goal.groupId,
              name: name,
              emoji: emojiController.text.trim().isEmpty
                  ? '🎯'
                  : emojiController.text.trim(),
              targetAmount: target,
              currentAmount: current,
              isCompleted: current >= target,
              sortOrder: goal.sortOrder,
              createdAt: goal.createdAt,
            ),
          );
    }
  }

  Future<void> _showAddGoalDialog(BuildContext context, WidgetRef ref) async {
    final emojiController = TextEditingController(text: '🎯');
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController(text: '0');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Target Amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Current Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (created == true) {
      final name = nameController.text.trim();
      final target = double.tryParse(targetController.text.trim()) ?? 0;
      final current = double.tryParse(currentController.text.trim()) ?? 0;
      if (name.isNotEmpty && target > 0) {
        await ref
            .read(goalsProvider.notifier)
            .addGoal(
              name: name,
              emoji: emojiController.text.trim().isEmpty
                  ? '🎯'
                  : emojiController.text.trim(),
              targetAmount: target,
              currentAmount: current,
            );
      }
    }
  }
}
