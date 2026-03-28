import 'package:flutter/material.dart';

/// Call this to show a quick confetti burst overlay on task completion.
void showCompletionOverlay(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CompletionOverlay(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CompletionOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _CompletionOverlay({required this.onDone});

  @override
  State<_CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<_CompletionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(_controller.value),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  static const _colors = [
    Color(0xFFD3643B),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFFFB923C),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
  ];

  // Fixed particle positions (normalized 0–1)
  static const _particles = [
    [0.1, 0.2], [0.3, 0.15], [0.5, 0.1], [0.7, 0.18], [0.9, 0.22],
    [0.15, 0.4], [0.4, 0.35], [0.6, 0.38], [0.85, 0.42],
    [0.05, 0.6], [0.25, 0.55], [0.55, 0.52], [0.75, 0.58], [0.95, 0.62],
    [0.2, 0.75], [0.45, 0.72], [0.65, 0.78], [0.88, 0.80],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final color = _colors[i % _colors.length];
      final radius = (1 - progress) * 8.0;
      final alpha = (1 - progress).clamp(0.0, 1.0);

      // Each particle falls down and fades
      final x = p[0] * size.width;
      final baseY = p[1] * size.height;
      final y = baseY + progress * 200;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Alternate between circles and squares
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: radius * 1.5, height: radius * 1.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
