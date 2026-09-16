import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Type used across the Hub, named for its job and sized from the design
/// (`docs/artifacts/blocnet-hunter-hub.html`): 32 coverage · 24 day-one title
/// · 20 gem-page name · 17 name/metrics · 15 row titles/body · 13 meta · 11
/// caps labels.
class HubType {
  const HubType._();

  /// 11px letter-spaced caps (section labels, metric labels, chips).
  static TextStyle caps(
    Color color, {
    FontWeight weight = FontWeight.w700,
    double tracking = 0.66,
  }) =>
      AppTypography.custom(
        size: 11,
        weight: weight,
        color: color,
        letterSpacing: tracking,
        height: 1.2,
      );

  static TextStyle meta(Color color, {FontWeight weight = FontWeight.w400}) =>
      AppTypography.custom(size: 13, weight: weight, color: color, height: 1.5);

  static TextStyle body(
    Color color, {
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
  }) =>
      AppTypography.custom(
          size: 15, weight: weight, color: color, height: height);

  /// Gem names and titles (15/650).
  static TextStyle rowTitle(Color color) => AppTypography.custom(
        size: 15,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: -0.15,
        height: 1.3,
      );

  /// Names and metric values (17/680).
  static TextStyle lead(Color color) => AppTypography.custom(
        size: 17,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.25,
        height: 1.25,
      );
}
