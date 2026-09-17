import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Outlined caps pill naming a badge's rarity (`EPIC`).
class BadgeRarityChip extends StatelessWidget {
  const BadgeRarityChip({
    super.key,
    required this.rarity,
    this.compact = false,
  });

  final BadgeRarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: rarity.displayName,
      color: rarity.tone,
      dense: compact,
      uppercase: true,
    );
  }
}

/// Outlined caps pill naming a badge or quest category (`SOCIAL`).
class BadgeCategoryChip extends StatelessWidget {
  const BadgeCategoryChip({
    super.key,
    required this.category,
    this.compact = false,
  });

  final BadgeCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: category.displayName,
      color: category.tone,
      dense: compact,
      uppercase: true,
    );
  }
}
