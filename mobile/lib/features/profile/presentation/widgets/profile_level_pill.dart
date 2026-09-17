import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:flutter/material.dart';

/// Compact "badge + level name" pill shown in the profile hero.
/// Tapping it opens the Levels screen.
class ProfileLevelPill extends StatelessWidget {
  const ProfileLevelPill({
    super.key,
    required this.level,
    this.maxNameWidth = 130,
  });

  final UserLevelModel level;
  final double maxNameWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.levels),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.xs, AppSpace.hair, AppSpace.hair, AppSpace.hair),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.full,
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LevelBadgeIcon(level: level, size: LevelBadgeSize.small),
            const SizedBox(width: AppSpace.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxNameWidth),
              child: Text(
                level.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.captionSize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.hair),
            Icon(
              Icons.chevron_right,
              size: AppIcon.sm,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
