import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../features/tasks/providers/task_provider.dart';

/// Runs a background timer every 60 seconds and auto-flips tasks to
/// TaskStatus.missed when their end time has passed and they are not completed.
class TaskStatusService {
  TaskStatusService._();
  static final TaskStatusService instance = TaskStatusService._();

  Timer? _timer;
  WidgetRef? _ref;

  void startWithRef(WidgetRef ref) {
    _ref = ref;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _checkMissed());
    _checkMissed();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkMissed() {
    final ref = _ref;
    if (ref == null) return;

    try {
      final tasksAsync = ref.read(allTasksProvider);
      tasksAsync.whenData((tasks) {
        final now = DateTime.now();
        for (final task in tasks) {
          if (task.status != TaskStatus.completed &&
              task.status != TaskStatus.missed &&
              task.endTime.isBefore(now)) {
            ref.read(taskNotifierProvider.notifier).updateTask(
              task.copyWith(status: TaskStatus.missed),
            );
          }
        }
      });
    } catch (_) {
      // Silently ignore — provider may not be ready
    }
  }
}
