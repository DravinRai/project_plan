import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';

class _TaskLayout {
  final TaskModel task;
  final int trackIndex;
  final int maxTracks;
  _TaskLayout(this.task, this.trackIndex, this.maxTracks);
}

class ClockPainter extends CustomPainter {
  final DateTime currentTime;
  final List<TaskModel> tasks;
  final bool isDark;

  ClockPainter({
    required this.currentTime,
    required this.tasks,
    required this.isDark,
  });

  bool _overlap(TaskModel a, TaskModel b) {
    return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
  }

  List<_TaskLayout> _computeLayout() {
    List<_TaskLayout> layouts = [];
    Set<TaskModel> visited = {};
    
    for (var task in tasks) {
      if (visited.contains(task)) continue;
      
      List<TaskModel> cluster = [];
      List<TaskModel> queue = [task];
      visited.add(task);
      
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        cluster.add(cur);
        
        for (var other in tasks) {
          if (!visited.contains(other) && _overlap(cur, other)) {
            visited.add(other);
            queue.add(other);
          }
        }
      }
      
      cluster.sort((a,b) => a.startTime.compareTo(b.startTime));
      
      List<int> tracks = List.filled(cluster.length, -1);
      int maxTrack = 0;
      
      for (int i = 0; i < cluster.length; i++) {
         Set<int> used = {};
         for (int j = 0; j < i; j++) {
           if (_overlap(cluster[i], cluster[j])) {
             used.add(tracks[j]);
           }
         }
         int t = 0;
         while (used.contains(t)) {
           t++;
         }
         tracks[i] = t;
         if (t > maxTrack) maxTrack = t;
      }
      
      int maxTracks = maxTrack + 1;
      for (int i = 0; i < cluster.length; i++) {
        layouts.add(_TaskLayout(cluster[i], tracks[i], maxTracks));
      }
    }
    return layouts;
  }

  Color _getTaskBaseColor(TaskModel task) {
    final title = task.title.toLowerCase();
    if (title.contains('deep work')) return const Color(0xFF1E88E5);
    if (title.contains('design')) return const Color(0xFFFFB74D);
    if (title.contains('client')) return const Color(0xFFBA68C8);
    if (title.contains('sync')) return const Color(0xFF81C784);
    
    final colors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFBA68C8), // Purple
      const Color(0xFF81C784), // Green
      const Color(0xFFE57373), // Red
      const Color(0xFF4DB6AC), // Teal
    ];
    return colors[task.title.hashCode.abs() % colors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    // Leave about 35% radius for outside labels
    final faceRadius = maxRadius * 0.65;

    // ── 1. Draw Clock Face Background ─────────────────────────
    // Soft outer shadow
    final shadowPath = Path()..addOval(Rect.fromCircle(center: center, radius: faceRadius));
    canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), 8, true);
    
    // Main face circle
    final facePaint = Paint()
      ..color = isDark ? const Color(0xFF1E2128) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, faceRadius, facePaint);
    
    // Extremely subtle border
    canvas.drawCircle(
      center, 
      faceRadius, 
      Paint()
        ..color = isDark ? Colors.white10 : Colors.black12 
        ..style = PaintingStyle.stroke 
        ..strokeWidth = 1
    );

    // ── 2. Draw Task Arcs (Donut Charts) ──────────────────────
    final layouts = _computeLayout();
    final innerBound = faceRadius * 0.45;
    final outerBound = faceRadius * 0.90;
    
    for (final layout in layouts) {
        final task = layout.task;
        final trackWidth = (outerBound - innerBound) / layout.maxTracks;
        final tInner = innerBound + trackWidth * layout.trackIndex;
        // Minor gap between concentric tracks
        final tOuter = tInner + trackWidth - (layout.maxTracks > 1 ? 4.0 : 0.0); 
        
        final startAngle = (task.startAngleDegrees - 90) * math.pi / 180;
        final sweepAngle = task.sweepAngleDegrees * math.pi / 180;
        
        final path = Path();
        path.arcTo(Rect.fromCircle(center: center, radius: tInner), startAngle, sweepAngle, true);
        path.arcTo(Rect.fromCircle(center: center, radius: tOuter), startAngle + sweepAngle, -sweepAngle, false);
        path.close();
        
        final baseColor = _getTaskBaseColor(task);
        final isDone = task.status == TaskStatus.completed;
        
        if (isDone) {
            // Solid filled chunk
            canvas.drawPath(path, Paint()..color = baseColor ..style = PaintingStyle.fill);
        } else {
            // Muted inner chunk + bright stroke
            canvas.drawPath(path, Paint()..color = baseColor.withValues(alpha: 0.2) ..style = PaintingStyle.fill);
            canvas.drawPath(path, Paint()
               ..color = baseColor 
               ..style = PaintingStyle.stroke 
               ..strokeWidth = 2.0 
               ..strokeJoin = StrokeJoin.round
            );
        }
    }

    // ── 3. Draw Edge Ticks ────────────────────────────────────
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < 60; i++) {
       final angle = i * 6 * math.pi / 180;
       final isHour = i % 5 == 0;
       final length = isHour ? faceRadius * 0.06 : faceRadius * 0.03;
       
       tickPaint.strokeWidth = isHour ? 2.0 : 1.5;
       tickPaint.color = isHour 
           ? (isDark ? Colors.white54 : Colors.black87) 
           : (isDark ? Colors.white24 : Colors.black26);

       final start = Offset(center.dx + (faceRadius - length) * math.cos(angle), center.dy + (faceRadius - length) * math.sin(angle));
       final end = Offset(center.dx + faceRadius * math.cos(angle), center.dy + faceRadius * math.sin(angle));
       canvas.drawLine(start, end, tickPaint);
    }

    // ── 4. Draw Numbers ───────────────────────────────────────
    final textStyle = TextStyle(
      color: isDark ? Colors.white : const Color(0xFF1E2128),
      fontSize: faceRadius * 0.16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    );

    for (var i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      // Inset numbers inside the arcs
      final x = center.dx + faceRadius * 0.72 * math.cos(angle);
      final y = center.dy + faceRadius * 0.72 * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(text: '$i', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // ── 5. Draw Outer Labels & Brackets ───────────────────────
    for (final layout in layouts) {
        final task = layout.task;
        final startAngle = (task.startAngleDegrees - 90) * math.pi / 180;
        final sweepAngle = task.sweepAngleDegrees * math.pi / 180;
        final midAngle = startAngle + sweepAngle / 2;
        final baseColor = _getTaskBaseColor(task);
        final isDone = task.status == TaskStatus.completed;

        // Draw outside bracket for completed tasks as seen in the mockup
        if (isDone) {
            final bracketRadius = faceRadius + 14; 
            final bracketPaint = Paint()
              ..color = baseColor.withValues(alpha: 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round;
            
            canvas.drawArc(
              Rect.fromCircle(center: center, radius: bracketRadius),
              startAngle,
              sweepAngle,
              false,
              bracketPaint,
            );
            
            final dotPaint = Paint()..color = baseColor ..style = PaintingStyle.fill;
            canvas.drawCircle(Offset(center.dx + bracketRadius * math.cos(startAngle), center.dy + bracketRadius * math.sin(startAngle)), 4.5, dotPaint);
            canvas.drawCircle(Offset(center.dx + bracketRadius * math.cos(startAngle + sweepAngle), center.dy + bracketRadius * math.sin(startAngle + sweepAngle)), 4.5, dotPaint);
        }

        // Draw Text Label
        final labelRadius = faceRadius + 32;
        final span = TextSpan(
          children: [
             TextSpan(
               text: '${task.title}\n', 
               style: TextStyle(
                 color: isDark ? Colors.white : Colors.black87, 
                 fontWeight: FontWeight.bold, 
                 fontSize: 11
               )
             ),
             TextSpan(
               text: isDone ? '(Done)' : '(Pending)', 
               style: TextStyle(
                 color: baseColor, 
                 fontSize: 10, 
                 fontWeight: FontWeight.w600
               )
             ),
          ]
        );
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
        
        // Push the text center slightly outward
        double lx = center.dx + labelRadius * math.cos(midAngle) - tp.width / 2;
        double ly = center.dy + labelRadius * math.sin(midAngle) - tp.height / 2;
        
        tp.paint(canvas, Offset(lx, ly));
    }

    // ── 6. Draw Hands ─────────────────────────────────────────
    final hourAngle = (currentTime.hour % 12 + currentTime.minute / 60) * 30 * math.pi / 180 - math.pi / 2;
    final minuteAngle = (currentTime.minute + currentTime.second / 60) * 6 * math.pi / 180 - math.pi / 2;

    final handPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF333333)
      ..strokeCap = StrokeCap.round;

    // Hour hand
    handPaint.strokeWidth = faceRadius * 0.05;
    canvas.drawLine(
      center, 
      Offset(center.dx + faceRadius * 0.48 * math.cos(hourAngle), center.dy + faceRadius * 0.48 * math.sin(hourAngle)), 
      handPaint
    );

    // Minute hand
    handPaint.strokeWidth = faceRadius * 0.035;
    canvas.drawLine(
      center, 
      Offset(center.dx + faceRadius * 0.75 * math.cos(minuteAngle), center.dy + faceRadius * 0.75 * math.sin(minuteAngle)), 
      handPaint
    );

    // Second hand (optional, thin red or dark gray)
    final secondAngle = currentTime.second * 6 * math.pi / 180 - math.pi / 2;
    final secondPaint = Paint()
      ..color = isDark ? Colors.grey : Colors.black38
      ..strokeWidth = faceRadius * 0.01
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center, 
      Offset(center.dx + faceRadius * 0.85 * math.cos(secondAngle), center.dy + faceRadius * 0.85 * math.sin(secondAngle)), 
      secondPaint
    );

    // Center dot
    canvas.drawCircle(center, faceRadius * 0.04, Paint()..color = handPaint.color);
    // Inner center pin
    canvas.drawCircle(center, faceRadius * 0.015, Paint()..color = isDark ? const Color(0xFF1E2128) : Colors.white);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime || 
           oldDelegate.tasks != tasks || 
           oldDelegate.isDark != isDark;
  }
}
