import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../providers/bill_reminder_provider.dart';
import '../common/editorial.dart';

class BillRemindersCard extends ConsumerWidget {
  const BillRemindersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(upcomingBillRemindersProvider);
    final active = reminders.where((r) => r.reminder.isActive).toList();

    return EditorialCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                'Bill Reminders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/settings/automation'),
                child: const Text('Manage'),
              ),
            ],
          ),
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No upcoming reminders.'),
            )
          else
            ...active.take(3).map((r) {
              final status = r.daysLeft < 0
                  ? 'Overdue'
                  : r.daysLeft == 0
                  ? 'Due today'
                  : 'In ${r.daysLeft} days';
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.reminder.title} · ${r.dueDate.monthDayYear}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: r.daysLeft < 0 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
