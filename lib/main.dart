import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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

  // ── Firebase Crashlytics ──────────────────────────────────────
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    // Pass all uncaught Flutter framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ── Firebase Analytics ────────────────────────────────────────
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await FirebaseAnalytics.instance.logAppOpen();
  }

  // ── Firebase App Check ────────────────────────────────────────
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  }

  // ── Hive initialization (Secure) ───────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  
  // Initialize with encryption key from secure storage
  const secureStorage = FlutterSecureStorage();
  String? base64Key = await secureStorage.read(key: 'hive_encryption_key');
  if (base64Key == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key', 
      value: base64UrlEncode(key),
    );
    base64Key = base64UrlEncode(key);
  }
  final encryptionKey = base64Url.decode(base64Key);
  
  await Hive.openBox<NoteModel>(
    'notes', 
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

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
        title: 'Pie',
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
