import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/task_status_service.dart';
import 'data/models/note_model.dart';
import 'features/settings/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Hive initialization ──────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  await Hive.openBox<NoteModel>('notes');

  // ── Notifications ─────────────────────────────────────────────
  await NotificationService.instance.init();

  // ── SharedPreferences ─────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ProjectPlanApp(),
    ),
  );
}

class ProjectPlanApp extends ConsumerStatefulWidget {
  const ProjectPlanApp({super.key});

  @override
  ConsumerState<ProjectPlanApp> createState() => _ProjectPlanAppState();
}

class _ProjectPlanAppState extends ConsumerState<ProjectPlanApp> {
  @override
  void initState() {
    super.initState();
    // Start missed-task detector after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a ProviderContainer-compatible ref via a helper
      TaskStatusService.instance.startWithRef(ref);
    });
  }

  @override
  void dispose() {
    TaskStatusService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final locale = Locale(settings.languageCode);

    final router = ref.watch(appRouterProvider);

    return _KeyboardShortcutsWrapper(
      child: MaterialApp.router(
        title: 'Project Plan',
        theme: AppTheme.light(primaryColor),
        darkTheme: AppTheme.dark(primaryColor),
        themeMode: settings.themeMode,
        locale: locale,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ── Keyboard Shortcuts ────────────────────────────────────────────

class _KeyboardShortcutsWrapper extends ConsumerWidget {
  final Widget child;
  const _KeyboardShortcutsWrapper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const _NewTaskIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _SearchIntent(),
      },
      child: Actions(
        actions: {
          _NewTaskIntent: CallbackAction<_NewTaskIntent>(
            onInvoke: (_) {
              router.push('/home/task-editor');
              return null;
            },
          ),
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (_) {
              router.push('/home/search');
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}
