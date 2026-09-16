import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_role_chip.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_role_style.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

/// Avatar, name, handle and lead role at the top of a public profile.
class PublicProfileIdentity extends StatelessWidget {
  const PublicProfileIdentity({
    super.key,
    required this.admin,
    required this.displayName,
    required this.username,
    required this.roleKey,
  });

  final Admin admin;

  /// From the public-profile API; wins over [admin]'s name when non-blank.
  final String? displayName;
  final String username;
  final String? roleKey;

  @override
  Widget build(BuildContext context) {
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : admin.name;
    final role = roleKey;

    return Column(
      children: [
        AppAvatar(
          radius: 42,
          imageUrl: admin.imageUrl,
          fallback: Text(
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'U',
            style: AppTypography.custom(
              color: AppColors.primary400,
              size: AppText.headlineSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: UserNameWithLevelIcon(
                name: name,
                currentLevel: admin.currentLevel,
                levelBadgeSize: LevelBadgeSize.small,
                textStyle: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.headlineSize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            if (admin.primaryBadge != null) ...[
              const SizedBox(width: AppSpace.sm),
              BadgeIcon(
                badge: admin.primaryBadge!,
                size: BadgeSize.medium,
                showTooltip: false,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          username,
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.bodySize,
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (role != null)
          ProfileRoleChip(
            label: publicProfileRoleLabel(role),
            textColor: publicProfileRoleTextColor(role),
            borderColor:
                publicProfileRoleTextColor(role).withValues(alpha: 0.55),
            backgroundColor:
                publicProfileRoleTextColor(role).withValues(alpha: 0.15),
          ),
      ],
    );
  }
}
