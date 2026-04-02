import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:project_plan/features/tasks/models/task_model.dart';
import 'package:project_plan/features/tasks/repositories/task_repository.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository Provider ───────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// ── Selected Date ─────────────────────────────────────────────

/// The currently viewed date (for daily list + clock view).
/// Defaults to today. User can switch to advance planning mode.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

// ── Task Streams ──────────────────────────────────────────────

final allTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).watchAllTasks(uid);
});

/// Returns a sorted list of unique dates that have at least one assigned/remaining task,
/// plus the current date and the selected date.
final activeDatesProvider = Provider.autoDispose<List<DateTime>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  final selectedDate = ref.watch(selectedDateProvider);
  final now = DateTime.now();

  final Set<String> uniqueDateStrings = {
    _fmt(selectedDate),
    _fmt(now),
    ...tasks.where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.missed).map((t) => t.date)
  };

  final dates = uniqueDateStrings.map((d) => DateTime.parse(d)).toList();
  dates.sort((a, b) => a.compareTo(b));
  return dates;
});

// ── Task Stream for Selected Date ─────────────────────────────

final tasksForDateProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final uid  = ref.watch(authStateProvider).valueOrNull?.uid;
  final date = ref.watch(selectedDateProvider);
  if (uid == null) return const Stream.empty();
  return ref
      .watch(taskRepositoryProvider)
      .watchTasksForDate(uid, _fmt(date));
});

// ── Task Sorting ──────────────────────────────────────────────

enum TaskSortOption { importance, dueDate, alphabetically, creationDate }

final taskSortProvider = StateProvider<TaskSortOption>((ref) {
  return TaskSortOption.creationDate; // Default sort
});

final sortedTasksForDateProvider = Provider.autoDispose<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(tasksForDateProvider);
  final sortOption = ref.watch(taskSortProvider);

  return tasksAsync.whenData((tasks) {
    // We create a copy of the list so we don't mutate the original stream data
    final sorted = List<TaskModel>.from(tasks);
    
    sorted.sort((a, b) {
      switch (sortOption) {
        case TaskSortOption.importance:
          // Important tasks first
          if (a.isImportant && !b.isImportant) return -1;
          if (!a.isImportant && b.isImportant) return 1;
          // Fallback to creation date if same importance
          return b.createdAt.compareTo(a.createdAt);
          
        case TaskSortOption.dueDate:
          // Tasks without due date go to the end
          if (a.dueDate == null && b.dueDate == null) return b.createdAt.compareTo(a.createdAt);
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
          
        case TaskSortOption.alphabetically:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          
        case TaskSortOption.creationDate:
          return b.createdAt.compareTo(a.createdAt); // Newest first
      }
    });

    return sorted;
  });
});

// ── Missed & Remaining ────────────────────────────────────────

final missedRemainingProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).watchMissedAndRemaining(uid);
});

// ── Task Actions Notifier ─────────────────────────────────────

class TaskNotifier extends AsyncNotifier<void> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  String get _uid => ref.read(authStateProvider).valueOrNull!.uid;

  @override
  Future<void> build() async {}

  Future<String> createTask(TaskModel task) async {
    state = const AsyncLoading();
    String id = '';
    state = await AsyncValue.guard(() async {
      id = await _repo.createTask(_uid, task);
    });
    return id;
  }

  Future<void> updateTask(TaskModel task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateTask(_uid, task));
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteTask(_uid, taskId));
  }

  Future<void> completeTask(TaskModel task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.completeTask(_uid, task));
  }

  Future<void> undoCompletion(TaskModel task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.undoCompletion(_uid, task));
  }

  Future<void> runMissedDetection() async {
    final date = ref.read(selectedDateProvider);
    await _repo.autoDetectMissed(_uid, _fmt(date));
  }
}

final taskNotifierProvider =
    AsyncNotifierProvider<TaskNotifier, void>(TaskNotifier.new);
