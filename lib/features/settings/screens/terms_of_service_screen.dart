import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1E293B);
    const bgColor = Color(0xFFF1F5F9);
    const headerColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: textColor, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Section(
              title: 'Terms of Service',
              content: 'Last Updated: March 2, 2026',
              textColor: textColor,
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '1. Acceptance of Terms',
              content: 'By accessing and using Pie, you accept and agree to be bound by the terms and provision of this agreement. Every user is expected to read these terms before proceeding.',
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            const _Section(
              title: '2. User Accounts',
              content: 'If you create an account on the application, you are responsible for maintaining the security of your account and you are fully responsible for all activities that occur under the account.',
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            const _Section(
              title: '3. Acceptable Use',
              content: 'You agree not to use the application to collect any personally identifiable information, including account names, or use the communication systems provided by the application for any commercial solicitation purposes.',
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            const _Section(
              title: '4. Modifications to Service',
              content: 'We reserve the right to modify or discontinue, temporarily or permanently, the service with or without notice. You agree that Pie shall not be liable to you or to any third party for any modification, suspension or discontinuance of the service.',
              textColor: textColor,
            ),
            const SizedBox(height: 32),
            Text(
              'For further inquiries regarding our Terms of Service, please contact support.',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.content,
    required this.textColor,
  });

  final String title;
  final String content;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
