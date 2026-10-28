import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for visual values.
/// Widgets must never inline colors, radii or spacing (ui-design.md §2).
///
/// Brand values come from overview.md; customise per product.
class AppColors {
  AppColors._();

  /// Main actions, links, accents.
  static const Color primary = Color(0xFF1E88E5);

  /// Highlights and support states.
  static const Color secondary = Color(0xFFF59E0B);

  /// Valid states and positive actions.
  static const Color success = Color(0xFF10B981);

  /// Destructive / error state.
  static const Color error = Color(0xFFEF4444);

  /// App background (light).
  static const Color background = Color(0xFFFAFAFA);

  /// Surface colour (light).
  static const Color surface = Colors.white;

  /// Dark-mode background.
  static const Color darkBackground = Color(0xFF111827);

  /// Dark-mode surface.
  static const Color darkSurface = Color(0xFF1F2937);

  /// Main text (light).
  static const Color textPrimary = Color(0xFF111827);

  /// Secondary text (light).
  static const Color textSecondary = Color(0xFF6B7280);

  /// Main text (dark).
  static const Color darkTextPrimary = Color(0xFFF9FAFB);

  /// Secondary text (dark).
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  /// Hairline dividers.
  static const Color divider = Color(0xFFE5E7EB);
}

/// Spacing scale (tokenised; no magic numbers in widgets).
class AppSpacing {
  AppSpacing._();

  /// 4 px.
  static const double xs = 4;

  /// 8 px.
  static const double sm = 8;

  /// 12 px.
  static const double md = 12;

  /// 16 px.
  static const double lg = 16;

  /// 24 px.
  static const double xl = 24;

  /// 32 px.
  static const double xxl = 32;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();

  /// 8 px — small controls.
  static const double sm = 8;

  /// 12 px — inputs and buttons.
  static const double md = 12;

  /// 16 px — cards.
  static const double lg = 16;
}
