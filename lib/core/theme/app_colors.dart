import 'package:flutter/material.dart';

/// Central color tokens for Project Plan.
/// Follows the blueprint color semantics:
///   Blue   → ASSIGNED tasks
///   Green  → COMPLETED tasks
///   Orange → MISSED tasks
///   Purple → REMAINING tasks
abstract class AppColors {
  // ── Task Status (Nuanced) ──────────────────────────────────
  static const Color assigned  = Color(0xFF60A5FA); // Brighter Blue
  static const Color completed = Color(0xFF34D399); // Emerald Green
  static const Color missed    = Color(0xFFFB923C); // Soft Orange
  static const Color remaining = Color(0xFFA78BFA); // Soft Purple

  // ── Brand (Deep & Premium) ───────────────────────────────
  static const Color primary      = Color(0xFFD3643B); // Rust / Orange
  static const Color primaryLight = Color(0xFFE5805B);
  static const Color primaryDark  = Color(0xFFA04523);

  // ── Surface (Light) ───────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color cardLight    = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // ── Surface (Dark - Deep Space) ──────────────────────────
  static const Color surfaceDark = Color(0xFF000000); // Pure Black
  static const Color cardDark    = Color(0xFF1A1A1A); // Deep Gray
  static const Color cardDarkElevated = Color(0xFF252525); // Slightly lighter for inner elements
  static const Color dividerDark = Color(0xFF2C2C2E);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0xFF9E9E9E); // Lighter gray for secondary

  // ── Effects & Glass ───────────────────────────────────────
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark  = Color(0x1AFFFFFF);
  static const Color glowColor        = Color(0x40D3643B);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient quoteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF000000)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
  );

  static const LinearGradient clockGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C2C2E), Color(0xFF1A1A1A)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF252525), Color(0xFF1A1A1A)],
  );
}
