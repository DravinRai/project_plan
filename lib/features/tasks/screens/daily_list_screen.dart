import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import '../providers/task_provider.dart';

/// FR-TASK-06: Daily chronological task list with status filters.
/// Supports swipe actions for quick complete / delete.
class DailyListScreen extends ConsumerWidget {
  const DailyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync   = ref.watch(tasksForDateProvider);
    final isDark       = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMM d').format(selectedDate)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
              onPressed: () => _pickDate(context, ref, selectedDate),
            ),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) {
          final msg = e.toString();
          if (msg.contains('permission-denied') || msg.contains('PERMISSION_DENIED')) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: Text('Error: $msg'));
        },
        data:    (tasks) => tasks.isEmpty
            ? _EmptyState(onAddTap: () => context.push('/home/task-editor'))
            : _TaskList(tasks: tasks, isDark: isDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag:  'daily_list_fab',
        onPressed: () => context.push('/home/task-editor'),
        icon:  const Icon(Icons.add_rounded, size: 24),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext ctx, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context:     ctx,
      initialDate: current,
      firstDate:   DateTime.now().subtract(const Duration(days: 365)),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }
}

// ── Task List ─────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks, required this.isDark});
  final List<TaskModel> tasks;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding:     const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount:   tasks.length,
      itemBuilder: (ctx, i) => _TaskTile(task: tasks[i], isDark: isDark),
    );
  }
}

// ── Task Tile with Swipe ──────────────────────────────────────

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, required this.isDark});
  final TaskModel task;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskNotifierProvider.notifier);
    final statusColor = _getStatusColor(task.status);

    return Dismissible(
      key:         ValueKey(task.taskId),
      background:  _swipeBg(AppColors.completed, Icons.check_circle_rounded,
          Alignment.centerLeft),
      secondaryBackground: _swipeBg(Colors.redAccent, Icons.delete_outline_rounded,
          Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          if (task.status == TaskStatus.completed) {
            await notifier.undoCompletion(task);
          } else {
            await notifier.completeTask(task);
          }
          return false;
        } else {
          return await _confirmDelete(context);
        }
      },
      onDismissed: (_) => notifier.deleteTask(task.taskId),
      child: Container(
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getStatusIcon(task.status), color: statusColor, size: 26),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              decoration: task.status == TaskStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
              color: task.status == TaskStatus.completed 
                  ? (isDark ? Colors.white38 : Colors.black38)
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
          subtitle: _Subtitle(task: task, isDark: isDark),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: () => context.push('/home/task-editor', extra: task),
        ),
      ),
    );
  }

  Widget _swipeBg(Color color, IconData icon, Alignment align) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: align,
      child: Icon(icon, color: color),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.completed => AppColors.completed,
      TaskStatus.missed    => AppColors.missed,
      TaskStatus.remaining => AppColors.remaining,
      TaskStatus.assigned  => AppColors.assigned,
    };
  }

  IconData _getStatusIcon(TaskStatus status) {
    return switch (status) {
      TaskStatus.completed => Icons.check_circle_rounded,
      TaskStatus.missed    => Icons.history_rounded,
      TaskStatus.remaining => Icons.pending_actions_rounded,
      TaskStatus.assigned  => Icons.schedule_rounded,
    };
  }

  Future<bool> _confirmDelete(BuildContext ctx) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (c) => AlertDialog(
            title:   const Text('Delete Activity'),
            content: const Text('Are you sure you want to remove this plan?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('CANCEL')),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.task, required this.isDark});
  final TaskModel task;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('h:mm a').format(task.startTime);
    final dur   = '${task.durationMinutes}m';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$start • $dur'
        '${task.category != null ? ' • ${task.category!.label}' : ''}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded,
              size: 72, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          const Text(
            'Clear Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'No activities planned for this day.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon:  const Icon(Icons.add_rounded),
            label: const Text('Add Activity'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
