import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The small uppercase role tag (`HUNTER`, `CORE TEAM`) beside an author's name
/// on a feed card. Tinted with the role's own colour, which is categorical and
/// deliberately independent of the brand accent.
class FeedRoleChip extends StatelessWidget {
  const FeedRoleChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.hair),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 0.8),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
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
