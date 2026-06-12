import 'package:flutter/material.dart';

/// Semantic color palette for the app, exposed as a [ThemeExtension] so
/// widgets resolve colors through the active theme.
///
/// Two palettes exist:
///  - [cream]: light neutral gray/cream with orange accents (soft edges)
///  - [carabinero]: deep red background, shell-red cards with black outlines
class AppColors extends ThemeExtension<AppColors> {
  /// Scaffold background.
  final Color bg;

  /// Card / dialog surfaces.
  final Color card;

  /// Inset fills (progress track, chips, input fills).
  final Color fill;

  /// Slightly deeper fill variant.
  final Color fillDeep;

  /// Hairline borders.
  final Color border;

  /// Stronger borders.
  final Color borderStrong;

  /// Primary text / icons.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Tertiary text / placeholders.
  final Color faint;

  /// Buttons, selected chips, timers — the "dark" accent.
  final Color accent;

  /// Text/icons rendered on [accent].
  final Color onAccent;

  /// Data emphasis: chart line, deltas, Log buttons, range pills.
  final Color data;

  /// Warm progress color (under-target bars, chart glow).
  final Color warm;

  /// In-zone / success.
  final Color green;

  /// Card outline (transparent in cream, black in carabinero).
  final Color cardOutline;

  const AppColors({
    required this.bg,
    required this.card,
    required this.fill,
    required this.fillDeep,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.data,
    required this.warm,
    required this.green,
    required this.cardOutline,
  });

  static const cream = AppColors(
    bg: Color(0xFFF7F5F2),
    card: Colors.white,
    fill: Color(0xFFEDEAE5),
    fillDeep: Color(0xFFE0DCD6),
    border: Color(0xFFDDDAD6),
    borderStrong: Color(0xFFCCC8C2),
    ink: Color(0xFF2C2C2C),
    muted: Color(0xFF6B6B6B),
    faint: Color(0xFF9E9E9E),
    accent: Color(0xFF1A1A1A),
    onAccent: Colors.white,
    data: Color(0xFFE8702A),
    warm: Color(0xFFE8702A),
    green: Color(0xFF4C8C4A),
    cardOutline: Colors.transparent,
  );

  static const carabinero = AppColors(
    bg: Color(0xFF7E1119),
    card: Color(0xFFC22730),
    fill: Color(0xFFA8161F),
    fillDeep: Color(0xFF8E0F1B),
    border: Color(0xFF42090D),
    borderStrong: Color(0xFF1C0506),
    ink: Color(0xFFFBEEE4),
    muted: Color(0xFFF3D2C8),
    faint: Color(0xFFE0A9A2),
    accent: Color(0xFF160708),
    onAccent: Color(0xFFFBEEE4),
    data: Color(0xFFFFDFC9),
    warm: Color(0xFFFF9148),
    green: Color(0xFF7BC476),
    cardOutline: Color(0xFF160708),
  );

  @override
  AppColors copyWith({Color? bg}) => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
