import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/settings_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────

/// Provides the SharedPreferences instance. Must be overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provides the SettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

// ── State Class ─────────────────────────────────────────────────────────

class SettingsState {
  final ThemeMode themeMode;
  final String languageCode;
  final bool notificationsEnabled;

  const SettingsState({
    required this.themeMode,
    required this.languageCode,
    required this.notificationsEnabled,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<SettingsState> {
  late final SettingsRepository _repository;

  @override
  SettingsState build() {
    _repository = ref.watch(settingsRepositoryProvider);

    return SettingsState(
      themeMode: _repository.getThemeMode(),
      languageCode: _repository.getLanguageCode(),
      notificationsEnabled: _repository.getNotificationsEnabled(),
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateLanguage(String code) async {
    await _repository.setLanguageCode(code);
    state = state.copyWith(languageCode: code);
  }

  Future<void> toggleNotifications(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
