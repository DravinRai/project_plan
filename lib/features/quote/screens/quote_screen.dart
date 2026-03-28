import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/quotes_data.dart';
import '../providers/quote_provider.dart';

/// FR-QUOTE-02: Full-screen, tap-to-dismiss daily motivational quote.
/// FR-QUOTE-04: Visually polished, native-feel.
class QuoteScreen extends ConsumerWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(todayQuoteProvider);

    return GestureDetector(
      onTap: () async {
        await markQuoteShownToday();
        ref.invalidate(shouldShowQuoteProvider);
        if (context.mounted) context.go('/home');
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── Ambient Background ───────────────────────────
            const _AmbientBackground(),

            // ── Glass Content Overlay ────────────────────────
            SafeArea(
              child: _QuoteContent(quote: quote),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ambient Background Animation ──────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : const Color(0xFFE2EAF4);
    
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Top Left Circle
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFD1DCE8),
              ),
            ),
          ),
          // Bottom Right Circle
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1F222A) : const Color(0xFFC4D5E5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quote Content ─────────────────────────────────────────────

class _QuoteContent extends StatefulWidget {
  const _QuoteContent({required this.quote});
  final QuoteData quote;

  @override
  State<_QuoteContent> createState() => _QuoteContentState();
}

class _QuoteContentState extends State<_QuoteContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),

              // ── Quote Header ──────────────────────────────
              const _QuoteMark(),

              const SizedBox(height: 48),

              // ── Quote Text ────────────────────────────────
              Text(
                widget.quote.text,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : AppColors.textPrimaryLight,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),

              // ── Author ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 2,
                    color: Theme.of(context).colorScheme.primary, // App primary color
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.quote.author.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppColors.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // ── Dismiss Hint ──────────────────────────────
              const Center(child: _DismissHint()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteMark extends StatelessWidget {
  const _QuoteMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform(
          transform: Matrix4.skewX(-0.4),
          child: Container(
            width: 16,
            height: 24,
            color: const Color(0xFFD9886C), // Peachy color
          ),
        ),
        const SizedBox(width: 8),
        Transform(
          transform: Matrix4.skewX(-0.4),
          child: Container(
            width: 16,
            height: 24,
            color: const Color(0xFFEBEBEB), // Silverish white
          ),
        ),
      ],
    );
  }
}

class _DismissHint extends StatelessWidget {
  const _DismissHint();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white54 : const Color(0xFF555555);

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Icon(
              Icons.keyboard_arrow_up_rounded,
              color: color,
              size: 28,
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          'TAP TO BEGIN YOUR DAY',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

