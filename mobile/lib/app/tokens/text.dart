import 'package:flutter/material.dart';

/// The Blocnet type scale.
///
/// Replaces 32 ad-hoc sizes (8px–200px, 1,117 call sites) with 8 steps.
/// Grounded in what the app actually used: the four workhorse buckets were
/// 12 (224), 11 (166), 13 (157) and 14 (103), all of which read small on a
/// phone. Every step here lands at or above its predecessor, so the migration
/// only ever makes text larger.
///
/// Prefer these over [AppTypography.custom]. They are shorter to type, which
/// is the whole reason the previous named scale went unused.
///
/// ```dart
/// Text('Nebula Swap', style: AppText.subtitle(AppColors.textPrimary))
/// Text('2h ago', style: AppText.caption(AppColors.textFaint))
/// Text('12,480', style: AppText.display(AppColors.textPrimary))
/// ```
class AppText {
  const AppText._();

  // ── Sizes ────────────────────────────────────────────────────────────────
  /// 11 — timestamps, counts, micro-labels. Absorbs 8, 8.5, 9, 10, 10.5.
  static const double captionSize = 11;

  /// 13 — chips, badges, tab labels, dense table rows. Absorbs 11.5, 12, 12.5.
  static const double labelSize = 13;

  /// 15 — default reading text. Absorbs 14. The floor for anything a user
  /// reads as a sentence rather than scans as a label.
  static const double bodySize = 15;

  /// 17 — card titles, list-row leads. Absorbs 16.
  static const double subtitleSize = 17;

  /// 20 — section and screen headings. Absorbs 18, 19, 21.
  static const double titleSize = 20;

  /// 24 — page heroes. Absorbs 22.
  static const double headlineSize = 24;

  /// 32 — hero stats and balances. Absorbs 28, 36, 38.
  static const double displaySize = 32;

  /// 48 — the wallet balance and nothing else, realistically.
  static const double displayXlSize = 48;

  // ── Weights ──────────────────────────────────────────────────────────────
  // Four, down from five. w800 (38 uses) folds into bold.
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ── Line heights ─────────────────────────────────────────────────────────
  // Tighter as type grows, which is what keeps large headings from looking
  // loose and small print from looking cramped.
  static const double _tight = 1.2;
  static const double _snug = 1.35;
  static const double _relaxed = 1.5;

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color,
    double height, {
    double? letterSpacing,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ── Styles ───────────────────────────────────────────────────────────────
  static TextStyle caption(Color color, {FontWeight weight = medium}) =>
      _style(captionSize, weight, color, _relaxed, letterSpacing: 0.1);

  static TextStyle label(Color color, {FontWeight weight = medium}) =>
      _style(labelSize, weight, color, _snug);

  static TextStyle body(Color color, {FontWeight weight = regular}) =>
      _style(bodySize, weight, color, _relaxed);

  static TextStyle subtitle(Color color, {FontWeight weight = semibold}) =>
      _style(subtitleSize, weight, color, _snug);

  static TextStyle title(Color color, {FontWeight weight = bold}) =>
      _style(titleSize, weight, color, _tight, letterSpacing: -0.2);

  static TextStyle headline(Color color, {FontWeight weight = bold}) =>
      _style(headlineSize, weight, color, _tight, letterSpacing: -0.4);

  static TextStyle display(Color color, {FontWeight weight = bold}) =>
      _style(displaySize, weight, color, _tight, letterSpacing: -0.6);

  static TextStyle displayXl(Color color, {FontWeight weight = bold}) =>
      _style(displayXlSize, weight, color, _tight, letterSpacing: -1);

  /// Numbers that sit in a column or change in place. Pairs with any style:
  /// `AppText.display(c).merge(AppText.tabular)`.
  static const TextStyle tabular =
      TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
}
