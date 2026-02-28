import 'package:flutter_test/flutter_test.dart';
import 'package:project_plan/features/quote/providers/quote_provider.dart';
import 'package:project_plan/features/quote/data/quotes_data.dart';
import 'package:project_plan/data/models/task_model.dart';

void main() {
  // ── Quote Logic Tests ────────────────────────────────────────
  group('Quote Provider', () {
    test('Same day returns same quote index', () {
      final day1 = DateTime(2025, 6, 10);
      final day2 = DateTime(2025, 6, 10);

      final idx1 = _dayOfYear(day1) % AppQuotes.quotes.length;
      final idx2 = _dayOfYear(day2) % AppQuotes.quotes.length;

      expect(idx1, equals(idx2));
    });

    test('Different days return different quote indices', () {
      final day1 = DateTime(2025, 6, 1);
      final day2 = DateTime(2025, 6, 2);

      final idx1 = _dayOfYear(day1) % AppQuotes.quotes.length;
      final idx2 = _dayOfYear(day2) % AppQuotes.quotes.length;

      expect(idx1, isNot(equals(idx2)));
    });

    test('Quote database has at least 30 entries', () {
      expect(AppQuotes.quotes.length, greaterThanOrEqualTo(30));
    });

    test('All quotes have non-empty text and author', () {
      for (final q in AppQuotes.quotes) {
        expect(q.text.trim(), isNotEmpty,
            reason: 'Quote text is empty');
        expect(q.author.trim(), isNotEmpty,
            reason: 'Quote author is empty for: ${q.text}');
      }
    });
  });

  // ── Task Model Tests ─────────────────────────────────────────
  group('TaskModel', () {
    late TaskModel baseTask;

    setUp(() {
      final now = DateTime(2025, 6, 10, 9, 0); // 09:00
      baseTask = TaskModel(
        taskId:          'test-task-1',
        userId:          'user-123',
        title:           'Morning Run',
        date:            '2025-06-10',
        startTime:       now,
        durationMinutes: 60,
        createdAt:       now,
        updatedAt:       now,
      );
    });

    test('Default status is ASSIGNED', () {
      expect(baseTask.status, equals(TaskStatus.assigned));
    });

    test('End time = startTime + durationMinutes', () {
      final expected = baseTask.startTime.add(const Duration(minutes: 60));
      expect(baseTask.endTime, equals(expected));
    });

    test('Clock start angle — 9:00 AM = 270° on a 12-hr face', () {
      // 9:00 → 9 * 30 = 270°
      expect(baseTask.startAngleDegrees, closeTo(270.0, 0.1));
    });

    test('Clock start angle — 12:00 = 0°', () {
      final task = baseTask.copyWith(
        startTime: DateTime(2025, 6, 10, 0, 0), // 12:00 AM
      );
      expect(task.startAngleDegrees, closeTo(0.0, 0.1));
    });

    test('Clock start angle — 6:00 PM = 180°', () {
      final task = baseTask.copyWith(
        startTime: DateTime(2025, 6, 10, 18, 0),
      );
      expect(task.startAngleDegrees, closeTo(180.0, 0.1));
    });

    test('Sweep angle — 60 min = 30°', () {
      // 60 / (12*60) * 360 = 30
      expect(baseTask.sweepAngleDegrees, closeTo(30.0, 0.1));
    });

    test('copyWith status COMPLETED clears nothing if not requested', () {
      final completed = baseTask.copyWith(
        status:      TaskStatus.completed,
        completedAt: DateTime(2025, 6, 10, 9, 55),
      );
      expect(completed.status, equals(TaskStatus.completed));
      expect(completed.completedAt, isNotNull);
    });

    test('copyWith clearCompletedAt reverts to null', () {
      final withTime = baseTask.copyWith(
        status:      TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      final reverted = withTime.copyWith(
        status:          TaskStatus.assigned,
        clearCompletedAt: true,
      );
      expect(reverted.completedAt, isNull);
      expect(reverted.status, equals(TaskStatus.assigned));
    });

    test('isOverdue — future task is not overdue', () {
      final future = baseTask.copyWith(
        startTime: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(future.isOverdue, isFalse);
    });

    test('isOverdue — completed task is never overdue', () {
      final completed = baseTask.copyWith(
        startTime:   DateTime.now().subtract(const Duration(hours: 3)),
        status:      TaskStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(completed.isOverdue, isFalse);
    });
  });
}

/// Mirrors the private helper in quote_provider.dart.
int _dayOfYear(DateTime date) {
  return date.difference(DateTime(date.year, 1, 1)).inDays;
}
