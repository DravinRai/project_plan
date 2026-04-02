import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import '../providers/task_provider.dart';

/// FR-TASK-05: Dedicated view for MISSED and overdue REMAINING tasks.
class TaskRemainingScreen extends ConsumerWidget {
  const TaskRemainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(missedRemainingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Backlog'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group by date
          final grouped = <String, List<TaskModel>>{};
          for (final t in tasks) {
            grouped.putIfAbsent(t.date, () => []).add(t);
          }
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: dates.length,
            itemBuilder: (ctx, i) {
              final date  = dates[i];
              final items = grouped[date]!;
              final label = _dateLabel(date);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...items.map((t) => _RemainingTile(task: t)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.completed.withAlpha(50)),
          const SizedBox(height: 16),
          const Text(
            'Inbox Zero!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'All your missed and remaining tasks\nare cleared.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _dateLabel(String dateStr) {
    final dt      = DateTime.parse(dateStr);
    final today   = DateTime.now();
    final diff    = DateTime(today.year, today.month, today.day)
        .difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(dt);
  }
}

class _RemainingTile extends ConsumerWidget {
  const _RemainingTile({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMissed  = task.status == TaskStatus.missed;
    final color     = isMissed ? AppColors.missed : AppColors.remaining;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final notifier  = ref.read(taskNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isMissed ? Icons.history_rounded : Icons.pending_actions_rounded,
            color: color,
            size: 26,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${DateFormat('h:mm a').format(task.startTime)} (${task.durationMinutes}m)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.completed, size: 32),
          onPressed: () => notifier.completeTask(task),
        ),
        onTap: () => context.push('/home/task-editor', extra: task),
      ),
    );
  }
}
