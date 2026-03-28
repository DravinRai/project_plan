import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/feedback_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(feedbackNotifierProvider.notifier).submitFeedback(
        subject: _subjectCtrl.text,
        message: _messageCtrl.text,
      );
      
      if (!mounted) return;
      
      // Success State
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Feedback sent! Thank you.'),
            ],
          ),
          backgroundColor: AppColors.completed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121418) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E202B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final feedbackState = ref.watch(feedbackNotifierProvider);
    final isSending = feedbackState is AsyncLoading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help & Feedback',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'d love to hear your suggestions or any issues you\'re facing.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              
              // Help Options
              _buildHelpOption(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Request a feature',
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              _buildHelpOption(
                icon: Icons.bug_report_outlined,
                title: 'Report a bug',
                color: Colors.redAccent,
              ),
              
              const SizedBox(height: 32),
              
              // Feedback Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildField(
                      controller: _subjectCtrl,
                      label: 'Subject',
                      hint: 'What is it about?',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _messageCtrl,
                      label: 'Message',
                      hint: 'Tell us more...',
                      maxLines: 5,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSending ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSending
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send Feedback',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (val) => val == null || val.isEmpty ? 'Cannot be empty' : null,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 15,
            ),
            filled: true,
            fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ],
      ),
    );
  }
}
