
import 'package:flutter_test/flutter_test.dart';
import 'package:project_plan/core/stubs/firestore_stub.dart';
import 'package:project_plan/data/models/task_model.dart';
import 'package:project_plan/data/repositories/task_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  test('Firestore Stub Persistence Test', () async {
    // 1. Setup Hive
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    final repo = TaskRepository();
    final uid  = 'test_user';
    
    final task = TaskModel(
      taskId: 'test_id',
      userId: uid,
      title: 'Test Task',
      date: '2026-02-22',
      startTime: DateTime.now(),
      durationMinutes: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('Creating task...');
    await repo.createTask(uid, task);

    print('Watching tasks...');
    final tasks = await repo.watchTasksForDate(uid, '2026-02-22').first;

    print('Found tasks: ${tasks.length}');
    expect(tasks.length, greaterThan(0));
    expect(tasks.any((t) => t.title == 'Test Task'), isTrue);
    
    print('Updating task...');
    final updatedTask = task.copyWith(title: 'Updated Task');
    await repo.updateTask(uid, updatedTask);
    
    final tasksAfterUpdate = await repo.watchTasksForDate(uid, '2026-02-22').first;
    expect(tasksAfterUpdate.any((t) => t.title == 'Updated Task'), isTrue);
    print('Test Passed!');
  });
}
