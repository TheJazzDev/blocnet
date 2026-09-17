import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// The Mine tab's colours, all taken from [AppColors].
///
/// The accent follows the space accent at runtime (`AppColors.primary500`),
/// as the Mine did before the 2026-09-11 redesign, so every tint is derived
/// from it rather than written as its own hex.
class MinePalette {
  const MinePalette._();

  // Grounds and edges.
  static const Color ground = AppColors.bgBase;
  static const Color card = AppColors.bgSurface;
  static const Color raised = AppColors.bgElevated;
  static const Color edge = AppColors.borderSubtle;
  static const Color strongEdge = AppColors.borderMuted;

  // Accent.
  static Color get accent => AppColors.primary500;
  static Color get accentSoft => AppColors.primary400;

  /// The old "EARNING PER HOUR" panel: an 8 % accent wash, 20 % edge.
  static Color get accentWash => accent.withValues(alpha: 0.08);
  static Color get accentEdge => accent.withValues(alpha: 0.2);

  // Status.
  static Color get amber => AppColors.warning500;
  static Color get success => AppColors.successColor;

  // Text.
  static Color get text => AppColors.textPrimary;
  static Color get secondary => AppColors.textSecondary;
  static Color get muted => AppColors.textMuted;
  static Color get faint => AppColors.textFaint;

  /// Scrim under the help popover.
  static Color get scrim => Colors.black.withValues(alpha: 0.6);
}
