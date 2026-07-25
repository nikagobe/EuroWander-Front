import 'package:flutter/material.dart';

/// 8dp grid-based spacing tokens.
/// Use these instead of magic numbers in SizedBox / EdgeInsets.
abstract final class AppSpacing {
  /// 2dp
  static const double xxxs = 2;

  /// 4dp
  static const double xxs = 4;

  /// 8dp — base unit
  static const double xs = 8;

  /// 12dp
  static const double sm = 12;

  /// 16dp
  static const double md = 16;

  /// 20dp
  static const double lg = 20;

  /// 24dp
  static const double xl = 24;

  /// 32dp
  static const double xxl = 32;

  /// 40dp
  static const double xxxl = 40;

  /// 48dp
  static const double huge = 48;

  /// 64dp
  static const double massive = 64;

  // ──────────────────────────────────────────────
  // Common EdgeInsets presets
  // ──────────────────────────────────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalXl =
      EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: xl);
}

/// Border radius tokens.
abstract final class AppRadius {
  /// 4dp — very subtle
  static const double xs = 4;

  /// 8dp — inputs, small chips
  static const double sm = 8;

  /// 12dp — buttons, cards
  static const double md = 12;

  /// 16dp — cards, containers
  static const double lg = 16;

  /// 20dp — prominent cards
  static const double xl = 20;

  /// 24dp — bottom sheets, modals
  static const double xxl = 24;

  /// 100dp — pill shape (chips, tags)
  static const double pill = 100;

  // ──────────────────────────────────────────────
  // Pre-built BorderRadius
  // ──────────────────────────────────────────────
  static final BorderRadius borderSm = BorderRadius.circular(sm);
  static final BorderRadius borderMd = BorderRadius.circular(md);
  static final BorderRadius borderLg = BorderRadius.circular(lg);
  static final BorderRadius borderXl = BorderRadius.circular(xl);
  static final BorderRadius borderXxl = BorderRadius.circular(xxl);
  static final BorderRadius borderPill = BorderRadius.circular(pill);
}

/// Elevation / shadow tokens.
abstract final class AppShadows {
  static List<BoxShadow> sm(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> md(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> lg(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> xl(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  /// Ambient glow (e.g., for primary CTA buttons)
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.30),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Animation duration tokens.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 300);
}

/// Common animation curves.
abstract final class AppCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
}
