import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
              title: 'Privacy Policy',
              content: 'Last Updated: February 28, 2026',
              textColor: textColor,
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '1. Information Collection',
              content: 'Pie collects minimal data necessary to provide and improve the service. This may include task names, schedules, and local app preferences saved on your device.',
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            const _Section(
              title: '2. Data Usage',
              content: 'Your data is used solely for the functionality of the time-blocking and consistency tracking features. We do not sell or share your personal information with third parties.',
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            const _Section(
              title: '3. Data Security',
              content: 'We implement industry-standard security measures to protect your data. Since most data is stored locally or via Firebase, security is partially managed by your device settings and Google Firebase authentication.',
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            const _Section(
              title: '4. Your Rights',
              content: 'You have the right to export or delete your data at any time through the Export Data and account management features within the app.',
              textColor: textColor,
            ),
            const SizedBox(height: 32),
            Text(
              'For further inquiries, please use the Feedback section in the Settings.',
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
