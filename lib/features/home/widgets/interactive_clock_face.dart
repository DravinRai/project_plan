import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import 'clock_painter.dart';

class InteractiveClockFace extends ConsumerStatefulWidget {
  final List<TaskModel> tasks;
  final bool isDark;

  const InteractiveClockFace({
    super.key,
    required this.tasks,
    required this.isDark,
  });

  @override
  ConsumerState<InteractiveClockFace> createState() => _InteractiveClockFaceState();
}

class _InteractiveClockFaceState extends ConsumerState<InteractiveClockFace> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Auto-refresh the clock every second to keep the hands moving
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Calculates which task was tapped based on touch coordinates relative to the center.
  void _handleTap(TapUpDetails details, Size size) {
    if (widget.tasks.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    
    // Matches logic in clock_painter
    final faceRadius = maxRadius * 0.65;
    
    // Check if the tap is within the clock face
    final tapPosition = details.localPosition;
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // If tap is outside the outer task arc boundary, ignore
    final innerBound = faceRadius * 0.40;
    final outerBound = faceRadius * 0.95;
    if (distance > outerBound || distance < innerBound) return;

    // Convert dx,dy to an angle in degrees. 
    // atan2 gives -pi to pi. We want 0 degrees at 12 o'clock, growing clockwise.
    double angle = math.atan2(dy, dx) * 180 / math.pi;
    angle = (angle + 90) % 360; 
    if (angle < 0) angle += 360;

    // Iterate tasks to find if the angle falls within a task's sweep
    for (final task in widget.tasks) {
      double start = task.startAngleDegrees;
      double end = start + task.sweepAngleDegrees;

      // Normalize angles to handle midnight crossing
      while (start >= 360) {
        start -= 360;
      }
      while (end >= 360) {
        end -= 360;
      }
      
      bool isHit = false;
      if (end < start) {
        // Crosses midnight (0/360 boundary)
        isHit = angle >= start || angle <= end;
      } else {
        isHit = angle >= start && angle <= end;
      }

      if (isHit) {
        // Pushing to the task editor with the selected task
        context.push('/home/task-editor', extra: task);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Expand fully to accommodate the labels
        final clockSize = math.min(constraints.maxWidth, 500.0);
        
        return Center(
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details, Size(clockSize, clockSize)),
            child: SizedBox(
              width: clockSize,
              height: clockSize,
              child: CustomPaint(
                painter: ClockPainter(
                  currentTime: _now,
                  tasks: widget.tasks,
                  isDark: widget.isDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
