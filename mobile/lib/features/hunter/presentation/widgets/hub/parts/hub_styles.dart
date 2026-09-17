import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Type used across the Hub, on the app's own scale ([AppText]).
///
/// The Hub follows the pre-2026-09-11 app: 10px letter-spaced caps for card
/// and section labels, 12px meta, 14px reading text, 16/18 for names.
class HubType {
  const HubType._();

  /// 10px letter-spaced caps (section labels, metric labels, pills).
  static TextStyle caps(
    Color color, {
    FontWeight weight = AppText.bold,
    double tracking = 1.0,
  }) =>
      AppText.caption(color, weight: weight).copyWith(letterSpacing: tracking);

  /// 12px secondary lines: counts, timestamps, captions.
  static TextStyle meta(Color color, {FontWeight weight = AppText.regular}) =>
      AppText.label(color, weight: weight);

  /// 14px reading text.
  static TextStyle body(
    Color color, {
    FontWeight weight = AppText.regular,
    double height = 1.5,
  }) =>
      AppText.body(color, weight: weight).copyWith(height: height);

  /// Gem names in rows and cards (14/700).
  static TextStyle rowTitle(Color color) =>
      AppText.body(color, weight: AppText.bold).copyWith(height: 1.35);

  /// The hunter's name, sheet titles (16/700).
  static TextStyle lead(Color color) =>
      AppText.subtitle(color, weight: AppText.bold);
}

/// The Hub's status colours, drawn from the core palette. Quiet is orange,
/// not red: red on the Hub is spent on open reports and nothing else.
class HubTone {
  const HubTone._();

  /// The hunter space accent: filled buttons, the FAB, reliable, invites.
  static Color get accent => AppColors.hunterAccent;

  /// Text and icons on [accent].
  static const Color onAccent = Colors.black;

  /// A quiet gem, a slipping standing, the handover warn button.
  static const Color quiet = AppColors.tagAirdrop;

  /// A due gem.
  static Color get due => AppColors.warning500;

  /// Open reports.
  static const Color report = AppColors.tagWarning;

  /// A current gem's tick.
  static Color get current => AppColors.successColor;

  /// The `HUNTER` role pill, as on the old feed cards.
  static const Color hunterRole = AppColors.tagPartnership;
}

/// Shared insets. The Hub keeps the old app's 16px screen gutter.
class HubInsets {
  const HubInsets._();

  static const double gutter = 16;
}
