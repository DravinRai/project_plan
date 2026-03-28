import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_utils.dart';

/// Status of a task — mirrors the Firestore enum string.
enum TaskStatus {
  assigned,  // Created, scheduled, not yet complete
  remaining, // Today's task still upcoming
  completed, // User marked as done
  missed,    // Scheduled time passed without completion (auto-detected)
}

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
    TaskStatus.assigned  => 'Assigned',
    TaskStatus.remaining => 'Remaining',
    TaskStatus.completed => 'Completed',
    TaskStatus.missed    => 'Missed',
  };
}

/// Categories a user can assign to a task.
enum TaskCategory {
  work, personal, health, learning, finance, social, other;

  String get label => switch (this) {
    TaskCategory.work     => 'Work',
    TaskCategory.personal => 'Personal',
    TaskCategory.health   => 'Health',
    TaskCategory.learning => 'Learning',
    TaskCategory.finance  => 'Finance',
    TaskCategory.social   => 'Social',
    TaskCategory.other    => 'Other',
  };
}

/// Firestore document model for /users/{uid}/tasks/{taskId}
class TaskModel {
  final String taskId;
  final String userId;
  final String title;
  final String date;           // YYYY-MM-DD (indexed)
  final DateTime startTime;
  final int durationMinutes;   // 15-min increments, max 480
  final TaskStatus status;
  final DateTime? completedAt; // Auto-recorded on completion
  final String? notes;
  final TaskCategory? category;
  final DateTime? dueDate;     // Separate deadline
  final String? reminder;      // Alert preference (e.g., '15m', '1h')
  final String? recurrence;    // Repeat rule (e.g., 'daily', 'weekly')
  final List<String>? attachments; // Mock file attachments
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isClockAssigned;  // Was it created via the clock drag interface?
  final bool isImportant;      // Marked as important

  const TaskModel({
    required this.taskId,
    required this.userId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    this.status = TaskStatus.assigned,
    this.completedAt,
    this.notes,
    this.category,
    this.dueDate,
    this.reminder,
    this.recurrence,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.isClockAssigned = false,
    this.isImportant = false,
  });

  /// Computed end time from startTime + durationMinutes.
  DateTime get endTime =>
      startTime.add(Duration(minutes: durationMinutes));

  /// Whether this task is currently overdue (past end time, not completed).
  bool get isOverdue =>
      DateTime.now().isAfter(endTime) && status != TaskStatus.completed;

  // ── Clock Arc Helpers ─────────────────────────────────────

  /// Returns the start angle in degrees on a 12-hour clock face.
  /// 12:00 = 0°, 6:00 = 180°
  double get startAngleDegrees {
    final hour   = startTime.hour % 12;
    final minute = startTime.minute;
    return (hour * 60 + minute) / (12 * 60) * 360;
  }

  /// Returns the sweep angle in degrees for this task's duration.
  double get sweepAngleDegrees =>
      durationMinutes / (12 * 60) * 360;

  // ── Firestore ─────────────────────────────────────────────

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TaskModel(
      taskId:          doc.id,
      userId:          data['userId']          as String? ?? '',
      title:           data['title']           as String? ?? '',
      date:            data['date']            as String? ?? '',
      startTime:       FirestoreUtils.parseDateTime(data['startTime']),
      durationMinutes: data['durationMinutes'] as int?    ?? 30,
      status:          TaskStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'assigned'),
        orElse: () => TaskStatus.assigned,
      ),
      completedAt: FirestoreUtils.tryParseDateTime(data['completedAt']),
      notes:    data['notes']    as String? ,
      category: data['category'] != null
          ? TaskCategory.values.firstWhere(
              (e) => e.name == data['category'],
              orElse: () => TaskCategory.other,
            )
          : null,
      dueDate: FirestoreUtils.tryParseDateTime(data['dueDate']),
      reminder:   data['reminder']   as String?,
      recurrence: data['recurrence'] as String?,
      attachments: (data['attachments'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: FirestoreUtils.parseDateTime(data['createdAt']),
      updatedAt: FirestoreUtils.parseDateTime(data['updatedAt']),
      isClockAssigned: data['isClockAssigned'] as bool? ?? false,
      isImportant: data['isImportant'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId':          userId,
    'title':           title,
    'date':            date,
    'startTime':       Timestamp.fromDate(startTime),
    'durationMinutes': durationMinutes,
    'status':          status.name,
    'completedAt':     completedAt != null
                         ? Timestamp.fromDate(completedAt!)
                         : null,
    'notes':           notes,
    'category':        category?.name,
    'dueDate':         dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'reminder':        reminder,
    'recurrence':      recurrence,
    'attachments':     attachments,
    'createdAt':       Timestamp.fromDate(createdAt),
    'updatedAt':       Timestamp.fromDate(updatedAt),
    'isClockAssigned': isClockAssigned,
    'isImportant':     isImportant,
  };

  TaskModel copyWith({
    String?       taskId,
    String?       title,
    String?       date,
    DateTime?     startTime,
    int?          durationMinutes,
    TaskStatus?   status,
    DateTime?     completedAt,
    String?       notes,
    TaskCategory? category,
    DateTime?     dueDate,
    String?       reminder,
    String?       recurrence,
    List<String>? attachments,
    bool?         isClockAssigned,
    bool?         isImportant,
    bool          clearCompletedAt = false,
    bool          clearDueDate = false,
    bool          clearReminder = false,
    bool          clearRecurrence = false,
  }) {
    return TaskModel(
      taskId:          taskId          ?? this.taskId,
      userId:          userId,
      title:           title           ?? this.title,
      date:            date            ?? this.date,
      startTime:       startTime       ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status:          status          ?? this.status,
      completedAt:     clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes:           notes           ?? this.notes,
      category:        category        ?? this.category,
      dueDate:         clearDueDate    ? null : (dueDate    ?? this.dueDate),
      reminder:        clearReminder   ? null : (reminder   ?? this.reminder),
      recurrence:      clearRecurrence ? null : (recurrence ?? this.recurrence),
      attachments:     attachments     ?? this.attachments,
      createdAt:       createdAt,
      updatedAt:       DateTime.now(),
      isClockAssigned: isClockAssigned ?? this.isClockAssigned,
      isImportant:     isImportant ?? this.isImportant,
    );
  }
}
