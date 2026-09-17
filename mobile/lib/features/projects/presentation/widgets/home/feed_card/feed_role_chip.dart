import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The small uppercase role tag (`HUNTER`, `CORE TEAM`) beside an author's name
/// on a feed card, in the old outlined style.
class FeedRoleChip extends StatelessWidget {
  const FeedRoleChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  /// Hunters read in violet and every other role in the accent, as the feed
  /// always drew them.
  static Color colorFor(String label) =>
      label == 'HUNTER' ? AppColors.tagPartnership : AppColors.primary400;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs + 2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.85), width: 0.8),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: color,
          size: AppText.captionSize,
          weight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
