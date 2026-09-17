import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Moderation's status colours, drawn from the core palette.
///
/// The space's own colour is the red of its space-switcher icon. Open work is
/// amber, a closed-in-favour outcome is green, anything settled is grey.
class ModTone {
  const ModTone._();

  /// The moderation space accent: its filled buttons and queue icons.
  static const Color accent = AppColors.tagWarning;

  /// Text and icons on [accent].
  static const Color onAccent = Colors.white;

  /// Open reports, pending appeals, quiet gems.
  static Color get open => AppColors.warning500;

  /// Resolved, approved, overturned.
  static Color get done => AppColors.successColor;

  /// Dismissed and other states that ask nothing.
  static Color get neutral => AppColors.textMuted;

  /// Under review.
  static Color get review => AppColors.tagPartnership;

  /// Screen gutter, the old app's 16px.
  static const double gutter = 16;
}
