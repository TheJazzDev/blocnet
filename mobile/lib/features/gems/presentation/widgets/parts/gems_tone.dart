import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:flutter/material.dart';

/// Colours Gems uses, all from [AppColors].
class GemsTone {
  const GemsTone._();

  /// The space accent: blue in User space, cyan in Hunter space.
  static Color get accent => AppColors.primary500;

  /// Text on [accent]: black on cyan, white on blue.
  static Color get onAccent =>
      accent.computeLuminance() > 0.4 ? Colors.black : Colors.white;

  /// A quiet gem. Orange, not red: red is kept for reports.
  static const Color quiet = AppColors.tagAirdrop;

  /// The pill colour for a standing, or null when it gets a grey pill.
  static Color? standing(ReliabilityStanding standing) {
    return switch (standing) {
      ReliabilityStanding.reliable => AppColors.successColor,
      ReliabilityStanding.slipping => AppColors.warning500,
      ReliabilityStanding.quiet => quiet,
      ReliabilityStanding.newHunter || ReliabilityStanding.unknown => null,
    };
  }
}
