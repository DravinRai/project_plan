import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../features/auth/providers/auth_provider.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/quote/screens/quote_screen.dart';
import '../../features/quote/providers/quote_provider.dart';
import '../../features/checklist/screens/checklist_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/insights/screens/streak_history_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/tasks/screens/task_remaining_screen.dart';
import '../../features/tasks/screens/task_editor_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/terms_of_service_screen.dart';
import '../../features/settings/screens/feedback_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';

// ── Route Definitions ──────────────────────────────────────────

enum AppRoute {
  login('/'),
  quote('/quote'),
  home('/home'),
  profile('profile'),
  checklist('checklist'),
  calendar('calendar'),
  taskRemaining('remaining'),
  taskEditor('task-editor'),
  clockScheduler('clock-scheduler'),
  taskDetail('task/:taskId'),
  historicalDay('history/:date'),
  feedback('feedback'),
  settings('settings'),
  notes('notes'),
  streakHistory('streak-history'),
  insights('insights'),
  search('search'),
  privacyPolicy('/privacy-policy'),
  termsOfService('/terms-of-service');

  final String path;
  const AppRoute(this.path);
}

// ── App Router Configuration ───────────────────────────────────

final appRouterProvider = riverpod.Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final shouldShowQuote = ref.watch(shouldShowQuoteProvider).valueOrNull ?? false;

  return GoRouter(
    initialLocation: AppRoute.login.path,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == AppRoute.login.path;
      final isOnQuotePage = state.matchedLocation == AppRoute.quote.path;
      final isPrivacyPolicy = state.matchedLocation == AppRoute.privacyPolicy.path;
      final isTermsOfService = state.matchedLocation == AppRoute.termsOfService.path;

      if (!isLoggedIn) {
        return (isLoggingIn || isPrivacyPolicy || isTermsOfService) ? null : AppRoute.login.path;
      }

      // User IS logged in
      if (shouldShowQuote) {
        if (!isOnQuotePage) return AppRoute.quote.path;
        return null; // Already on quote page
      }

      // User is logged in and quote already shown or shouldn't be shown
      if (isLoggingIn || isOnQuotePage) {
        return AppRoute.home.path;
      }

      return null;
    },
    routes: [
      // ── Public Routes ────────────────────────────────────────
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.quote.path,
        name: AppRoute.quote.name,
        builder: (_, __) => const QuoteScreen(),
      ),
      GoRoute(
        path: AppRoute.privacyPolicy.path,
        name: AppRoute.privacyPolicy.name,
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoute.termsOfService.path,
        name: AppRoute.termsOfService.name,
        builder: (_, __) => const TermsOfServiceScreen(),
      ),

      // ── Main Shell ────────────────────────────────────────
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: AppRoute.profile.path,
            name: AppRoute.profile.name,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoute.checklist.path,
            name: AppRoute.checklist.name,
            builder: (_, __) => const ChecklistScreen(),
          ),
          GoRoute(
            path: AppRoute.taskRemaining.path,
            name: AppRoute.taskRemaining.name,
            builder: (_, __) => const TaskRemainingScreen(),
          ),
          GoRoute(
            path: AppRoute.calendar.path,
            name: AppRoute.calendar.name,
            builder: (_, __) => const CalendarScreen(),
            routes: [
              GoRoute(
                path: ':date',
                name: AppRoute.historicalDay.name,
                builder: (context, state) {
                  final date = state.pathParameters['date'] ?? '';
                  return _PlaceholderScreen(title: 'History — $date');
                },
              ),
            ],
          ),
          GoRoute(
            path: 'feedback',
            name: AppRoute.feedback.name,
            builder: (_, __) => const FeedbackScreen(),
          ),
           GoRoute(
            path: 'settings',
            name: AppRoute.settings.name,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'notes',
            name: AppRoute.notes.name,
            builder: (_, __) => const NotesScreen(),
          ),
          GoRoute(
            path: 'task-editor',
            name: AppRoute.taskEditor.name,
            builder: (context, state) {
              final task = state.extra as TaskModel?;
              return TaskEditorScreen(existingTask: task);
            },
          ),
          GoRoute(
            path: 'streak-history',
            name: AppRoute.streakHistory.name,
            builder: (_, __) => const StreakHistoryScreen(),
          ),
          GoRoute(
            path: 'insights',
            name: AppRoute.insights.name,
            builder: (_, __) => const InsightsScreen(),
          ),
          GoRoute(
            path: 'search',
            name: AppRoute.search.name,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: 'clock-scheduler',
            name: AppRoute.clockScheduler.name,
            builder: (_, __) => const _PlaceholderScreen(title: 'Clock Scheduler'),
          ),
          GoRoute(
            path: 'task/:taskId',
            name: AppRoute.taskDetail.name,
            builder: (context, state) {
              final taskId = state.pathParameters['taskId'] ?? '';
              return _PlaceholderScreen(title: 'Task $taskId');
            },
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoute.home.path),
              child: const Text('Back Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ── Temporary Placeholder ──────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$title arriving soon...',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
