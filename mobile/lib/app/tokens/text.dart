import 'package:flutter/material.dart';

/// The Blocnet type scale.
///
/// Replaces 32 ad-hoc sizes (8px–200px, 1,117 call sites) with 8 steps.
/// The values are the app's own pre-2026-09-11 workhorse sizes — 12 (224),
/// 11 (166), 13 (157) and 14 (103). A larger scale was tried and rejected by
/// the owner as too loud on a phone (F-67), so these stay moderate.
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
  /// 10 — timestamps, counts, micro-labels.
  static const double captionSize = 10;

  /// 12 — chips, badges, tab labels, dense table rows.
  static const double labelSize = 12;

  /// 14 — default reading text. The floor for anything a user reads as a
  /// sentence rather than scans as a label.
  static const double bodySize = 14;

  /// 16 — card titles, list-row leads.
  static const double subtitleSize = 16;

  /// 18 — section and screen headings.
  static const double titleSize = 18;

  /// 22 — page heroes.
  static const double headlineSize = 22;

  /// 28 — hero stats and balances.
  static const double displaySize = 28;

  /// 40 — the wallet balance and nothing else, realistically.
  static const double displayXlSize = 40;

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
