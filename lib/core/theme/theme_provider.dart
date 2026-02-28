import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

/// Provider for managing the current [ThemeMode] (System, Light, Dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});

/// Provider for managing the primary accent color ("Color way").
final primaryColorProvider = StateProvider<Color>((ref) {
  return AppColors.primary;
});

/// Provider for managing the background image URL (if any).
final backgroundPhotoProvider = StateProvider<String?>((ref) => null);
