import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// "3 new posts" / "1 new comment": an outlined accent pill that jumps to the
/// newest items.
class CommunityNewItemsPill extends StatelessWidget {
  const CommunityNewItemsPill({
    super.key,
    required this.count,
    required this.noun,
    required this.onTap,
    this.icon = Icons.arrow_upward_rounded,
  });

  final int count;

  /// Singular; an "s" is added for more than one.
  final String noun;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary400;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.full,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIcon.xs, color: accent),
              const SizedBox(width: AppSpace.xs),
              Text(
                '$count new $noun${count == 1 ? '' : 's'}',
                style: AppTypography.custom(
                  color: accent,
                  size: AppText.labelSize,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
