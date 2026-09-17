import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:flutter/material.dart';

/// Colours for badge categories, drawn from the core palette.
///
/// The model still carries its own hex values for older callers; the
/// Progress screens (badges, quests) read these instead so they stay on
/// [AppColors].
extension BadgeCategoryTone on BadgeCategory {
  Color get tone => switch (this) {
        BadgeCategory.engagement => AppColors.primary500,
        BadgeCategory.mining => AppColors.successColor,
        BadgeCategory.social => AppColors.tagInfo,
        BadgeCategory.trust => AppColors.warning500,
        BadgeCategory.special => AppColors.tagPartnership,
      };
}

/// Colours for badge rarities, drawn from the core palette.
extension BadgeRarityTone on BadgeRarity {
  Color get tone => switch (this) {
        BadgeRarity.common => AppColors.tagGeneral,
        BadgeRarity.rare => AppColors.tagInfo,
        BadgeRarity.epic => AppColors.tagPartnership,
        BadgeRarity.legendary => AppColors.warning500,
      };
}

/// Returns [raw] when it reads as a sentence meant for people, otherwise
/// [fallback]. The Progress stores pass `error.toString()` through when a
/// request fails without an API message, which would put
/// `SocketException: ...` on screen.
String progressErrorText(String? raw, {required String fallback}) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty || text.length > 140) return fallback;
  const markers = [
    'exception',
    'error:',
    'socket',
    'http',
    'request failed',
    'timeout',
    '{',
    '<',
  ];
  final lower = text.toLowerCase();
  if (markers.any(lower.contains)) return fallback;
  return text;
}
