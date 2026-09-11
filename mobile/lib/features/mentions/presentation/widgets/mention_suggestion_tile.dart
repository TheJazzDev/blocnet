import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/mentions/data/models/mention_user_model.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

/// One row in the `@mention` autocomplete overlay.
class MentionSuggestionTile extends StatelessWidget {
  const MentionSuggestionTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  final MentionUserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.smValue),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
        child: Row(
          children: [
            AppAvatar(
              radius: 16,
              imageUrl: user.avatarUrl,
              backgroundColor: AppColors.primary400.withValues(alpha: 0.2),
              fallback: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserNameWithLevelIcon(
                    name: user.displayName ?? user.username,
                    currentLevel: user.currentLevel,
                    levelBadgeSize: LevelBadgeSize.tiny,
                    iconSpacing: 4,
                    textStyle: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
