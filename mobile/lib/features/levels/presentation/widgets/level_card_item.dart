import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:flutter/material.dart';

/// Square-ish tile for a level inside a tier section (card view mode).
/// Three of these sit side by side per tier.
class LevelCardItem extends StatelessWidget {
  const LevelCardItem({
    super.key,
    required this.level,
    required this.isCurrent,
    required this.isLocked,
    required this.tierColor,
    required this.onTap,
  });

  final UserLevelModel level;
  final bool isCurrent;
  final bool isLocked;
  final Color tierColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderAlpha = isCurrent ? 0.45 : (isLocked ? 0.16 : 0.3);

    return Material(
      color: isCurrent ? tierColor.withValues(alpha: 0.08) : AppColors.bgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tierColor.withValues(alpha: borderAlpha),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 18,
                child: Center(child: _buildStatus()),
              ),
              const SizedBox(height: 6),
              Opacity(
                opacity: isLocked ? 0.4 : 1,
                child: LevelBadge(
                  level: level,
                  size: LevelBadgeSize.large,
                  showName: false,
                  showLevelNumber: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                level.name,
                style: AppTypography.custom(
                  color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                  size: 12,
                  weight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Level ${level.level}',
                style: AppTypography.custom(
                  color: isLocked ? AppColors.textFaint : tierColor,
                  size: 10,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    if (isCurrent) {
      return LevelStatusChip(label: 'CURRENT', color: tierColor);
    }
    if (isLocked) {
      return Icon(
        Icons.lock_outline_rounded,
        size: 14,
        color: tierColor.withValues(alpha: 0.55),
      );
    }
    return Icon(
      Icons.check_circle_rounded,
      size: 14,
      color: tierColor.withValues(alpha: 0.85),
    );
  }
}
