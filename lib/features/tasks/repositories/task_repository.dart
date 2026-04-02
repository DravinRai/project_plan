import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repository for all task CRUD operations.
/// Write to Firestore first; Hive cache is updated on successful reads.
/// Firestore handles offline persistence natively via its own local cache.
/// Hive is used as a secondary fast read cache for the clock and list views.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _hiveBoxName = 'tasks_cache';

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  // ── Hive Box ─────────────────────────────────────────────

  Future<Box> get _box async {
    if (Hive.isBoxOpen(_hiveBoxName)) {
      return Hive.box(_hiveBoxName);
    }
    
    const secureStorage = FlutterSecureStorage();
    String? base64Key = await secureStorage.read(key: 'hive_encryption_key');
    if (base64Key == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_encryption_key', 
        value: base64UrlEncode(key),
      );
      base64Key = base64UrlEncode(key);
    }
    final encryptionKey = base64Url.decode(base64Key);

    return Hive.openBox(
      _hiveBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  // ── Create ────────────────────────────────────────────────

  /// Creates a new task. Returns the generated [taskId].
  Future<String> createTask(String uid, TaskModel task) async {
    try {
      final ref  = _col(uid).doc(task.taskId);
      final now  = DateTime.now();
      final data = task
          .copyWith()
          .toFirestore()
        ..['createdAt'] = Timestamp.fromDate(now)
        ..['updatedAt'] = Timestamp.fromDate(now);

      await ref.set(data);

      final savedTask = task.copyWith();
      final box = await _box;
      await box.put(ref.id, _sanitizeForHive(savedTask.toFirestore()));

      return ref.id;
    } catch (e) {
      // ignore: avoid_print
      rethrow;
    }
  }

  // ── Read / Watch ──────────────────────────────────────────

  /// Streams all tasks for a user, regardless of date.
  Stream<List<TaskModel>> watchAllTasks(String uid) {
    return _col(uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                TaskModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Streams all tasks for [uid] on a given [date] (YYYY-MM-DD), ordered by startTime.
  Stream<List<TaskModel>> watchTasksForDate(String uid, String date) {
    return _col(uid)
        .where('date', isEqualTo: date)
        .orderBy('startTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                TaskModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// One-shot fetch of all tasks for a date (used for historical view).
  Future<List<TaskModel>> getTasksForDate(String uid, String date) async {
    final snap = await _col(uid)
        .where('date', isEqualTo: date)
        .orderBy('startTime')
        .get();
    return snap.docs
        .map((d) =>
            TaskModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Fetch a single task by ID.
  Future<TaskModel?> getTask(String uid, String taskId) async {
    final doc = await _col(uid).doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  // ── Update ────────────────────────────────────────────────

  Future<void> updateTask(String uid, TaskModel task) async {
    await _col(uid).doc(task.taskId).update({
      ...task.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final box = await _box;
    await box.put(task.taskId, _sanitizeForHive(task.toFirestore()));
  }

  // ── Helpers ──────────────────────────────────────────────

  Map<String, dynamic> _sanitizeForHive(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    copy.forEach((key, value) {
      if (value is Timestamp) {
        copy[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        copy[key] = _sanitizeForHive(value);
      }
    });
    return copy;
  }

  // ── Status Transitions ────────────────────────────────────

  /// Marks a task COMPLETED and records [completedAt] timestamp.
  /// If [task.recurrence] is set, automatically schedules the next instance.
  Future<TaskModel> completeTask(String uid, TaskModel task) async {
    final now       = DateTime.now();
    final completed = task.copyWith(
      status:      TaskStatus.completed,
      completedAt: now,
    );
    await updateTask(uid, completed);

    if (task.recurrence != null && task.recurrence!.isNotEmpty) {
      await _generateNextRecurrence(uid, task);
    }

    return completed;
  }

  Future<void> _generateNextRecurrence(String uid, TaskModel task) async {
    DateTime nextTime = task.startTime;
    switch (task.recurrence?.toLowerCase()) {
      case 'daily':
        nextTime = nextTime.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextTime = nextTime.add(const Duration(days: 7));
        break;
      case 'weekdays':
        do {
          nextTime = nextTime.add(const Duration(days: 1));
        } while (nextTime.weekday == DateTime.saturday || nextTime.weekday == DateTime.sunday);
        break;
      case 'monthly':
        nextTime = DateTime(nextTime.year, nextTime.month + 1, nextTime.day, nextTime.hour, nextTime.minute);
        break;
      case 'yearly':
        nextTime = DateTime(nextTime.year + 1, nextTime.month, nextTime.day, nextTime.hour, nextTime.minute);
        break;
      default:
        return; // Unknown rule, don't generate
    }

    final year = nextTime.year.toString().padLeft(4, '0');
    final month = nextTime.month.toString().padLeft(2, '0');
    final day = nextTime.day.toString().padLeft(2, '0');
    final dateString = '$year-$month-$day';

    final nextTaskId = _col(uid).doc().id; // Generate new unique ID
    
    // Check if we already have a due date, if so, shift it
    DateTime? nextDue;
    if (task.dueDate != null) {
      final diff = task.dueDate!.difference(task.startTime);
      nextDue = nextTime.add(diff);
    }

    final nextTask = task.copyWith(
      taskId: nextTaskId,
      date: dateString,
      startTime: nextTime,
      dueDate: nextDue,
      status: TaskStatus.assigned,
      clearCompletedAt: true,
    );

    await createTask(uid, nextTask);
  }

  /// Reverts a COMPLETED task back to ASSIGNED (undo completion).
  Future<TaskModel> undoCompletion(String uid, TaskModel task) async {
    final reverted = task.copyWith(
      status:          TaskStatus.assigned,
      clearCompletedAt: true,
    );
    await updateTask(uid, reverted);
    return reverted;
  }

  /// Bulk-marks overdue ASSIGNED/REMAINING tasks as MISSED.
  Future<void> autoDetectMissed(String uid, String date) async {
    final tasks = await getTasksForDate(uid, date);

    final batch = _firestore.batch();
    for (final task in tasks) {
      if (task.isOverdue &&
          task.status != TaskStatus.completed &&
          task.status != TaskStatus.missed) {
        batch.update(_col(uid).doc(task.taskId), {
          'status':    TaskStatus.missed.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteTask(String uid, String taskId) async {
    await _col(uid).doc(taskId).delete();
    final box = await _box;
    await box.delete(taskId);
  }

  // ── Missed / Remaining ────────────────────────────────────

  /// Streams all MISSED + overdue REMAINING tasks for the user.
  Stream<List<TaskModel>> watchMissedAndRemaining(String uid) {
    return _col(uid)
        .where('status', whereIn: [TaskStatus.missed.name, TaskStatus.remaining.name])
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                TaskModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }
}
