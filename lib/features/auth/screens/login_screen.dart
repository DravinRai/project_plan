import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/gestures.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _clockController;

  @override
  void initState() {
    super.initState();
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _clockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.missed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Minimalist light gray
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // ── App Name (Typing Animation) ──────────────────────
                const _TypingAppName().animate().fadeIn(duration: 800.ms),
                
                const SizedBox(height: 60),

                // ── Meticulously Crafted Animated Clock ──────────────
                SizedBox(
                  width: 280,
                  height: 280,
                  child: AnimatedBuilder(
                    animation: _clockController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _PieClockPainter(
                          animationValue: _clockController.value,
                        ),
                      );
                    },
                  ),
                ).animate()
                 .scale(duration: 1000.ms, curve: Curves.easeOutBack)
                 .fadeIn(duration: 800.ms),

                const SizedBox(height: 80),

                // ── Login Action ─────────────────────────────────────
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _GoogleSignInButton(
                    isLoading: authNotifier.isLoading,
                    onTap: () => ref
                        .read(authNotifierProvider.notifier)
                        .signInWithGoogle(),
                  ),
                ).animate()
                 .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut)
                 .fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // ── Secondary Actions ────────────────────────────────
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By signing in you agree to our\n'),
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.pushNamed(AppRoute.termsOfService.name),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.pushNamed(AppRoute.privacyPolicy.name),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _TypingAppName extends StatefulWidget {
  const _TypingAppName();

  @override
  State<_TypingAppName> createState() => _TypingAppNameState();
}

class _TypingAppNameState extends State<_TypingAppName> {
  final String _text = "Pie";
  String _displayedText = "";

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i <= _text.length; i++) {
      if (!mounted) return;
      setState(() {
        _displayedText = _text.substring(0, i);
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E293B),
        letterSpacing: -1.0,
      ),
    );
  }
}

class _PieClockPainter extends CustomPainter {
  final double animationValue;

  _PieClockPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center + const Offset(0, 8), radius, shadowPaint);

    // 2. Metallic Outer Ring
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCBD5E1), Color(0xFFF8FAFC), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ringPaint);

    // 3. Inner White Face
    final facePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.92, facePaint);

    // 4. Stationary Orange Pie Slice (Stationary slice)
    final piePaint = Paint()
      ..color = const Color(0xFFFFD19A).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
      
    // Manually approximate the arc to bypass Flutter Windows drawArc hairline bugs
    final piePath = Path()..moveTo(center.dx, center.dy);
    const int segments = 30;
    const double startAngle = -math.pi / 2.8;
    const double sweepAngle = math.pi / 2.5;
    
    for (int i = 0; i <= segments; i++) {
      final double theta = startAngle + sweepAngle * (i / segments);
      piePath.lineTo(
        center.dx + (radius * 0.85) * math.cos(theta),
        center.dy + (radius * 0.85) * math.sin(theta),
      );
    }
    piePath.close();
    
    canvas.drawPath(piePath, piePaint);

    // 5. Markers (Ticks)
    final tickPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 1.5;
    
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180;
      final isMajor = i % 5 == 0;
      final innerRadius = isMajor ? radius * 0.85 : radius * 0.88;
      final outerRadius = radius * 0.9;
      
      canvas.drawLine(
        Offset(center.dx + innerRadius * math.cos(angle), center.dy + innerRadius * math.sin(angle)),
        Offset(center.dx + outerRadius * math.cos(angle), center.dy + outerRadius * math.sin(angle)),
        tickPaint..strokeWidth = isMajor ? 2.0 : 1.0,
      );
    }

    // 6. Hour/Minute Hands (Animated)
    final minuteAngle = (animationValue * 2 * math.pi) - (math.pi / 2);
    final hourAngle = (animationValue / 12 * 2 * math.pi) - (math.pi / 2) + (math.pi / 6 * 1.5); // Offset to look natural

    // Minute Hand (Darker/Sleeker)
    final minuteHandPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.75 * math.cos(minuteAngle), center.dy + radius * 0.75 * math.sin(minuteAngle)),
      minuteHandPaint,
    );

    // Hour Hand
    final hourHandPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.5 * math.cos(hourAngle), center.dy + radius * 0.5 * math.sin(hourAngle)),
      hourHandPaint,
    );

    // 7. Center Hub
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(center, 2, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _PieClockPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
