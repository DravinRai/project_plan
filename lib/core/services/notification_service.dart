import 'package:project_plan/features/tasks/models/task_model.dart';

/// Notification service stub — architecture is in place.
/// Windows toast integration can be configured when 
/// WindowsInitializationSettings GUID is set up per-machine.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> init() async {
    // Will be populated when real notification backend is configured
  }

  Future<void> showTaskReminder(TaskModel task) async {
    // TODO: wire flutter_local_notifications when Windows appUserModelId is configured
  }

  Future<void> cancelReminder(String taskId) async {}
}
