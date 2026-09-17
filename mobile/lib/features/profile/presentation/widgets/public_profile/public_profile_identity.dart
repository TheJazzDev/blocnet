import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_pill.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_avatar.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_role_style.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

/// Avatar, name, handle and lead role, left-aligned, at the top of a
/// public profile.
class PublicProfileIdentity extends StatelessWidget {
  const PublicProfileIdentity({
    super.key,
    required this.admin,
    required this.displayName,
    required this.avatarUrl,
    required this.handle,
    required this.roleKey,
  });

  final Admin admin;

  /// From the public-profile API; wins over [admin]'s name when non-blank.
  final String? displayName;
  final String? avatarUrl;

  /// `@username`, or null when the caller does not know it.
  final String? handle;
  final String? roleKey;

  @override
  Widget build(BuildContext context) {
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (admin.name.trim().isNotEmpty ? admin.name.trim() : 'Member');
    final role = roleKey;
    final image =
        (avatarUrl?.trim().isNotEmpty ?? false) ? avatarUrl : admin.imageUrl;

    return Row(
      children: [
        ProfileAvatar(name: name, imageUrl: image, size: 56),
        AppSpace.wGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: UserNameWithLevelIcon(
                      name: name,
                      currentLevel: admin.currentLevel,
                      levelBadgeSize: LevelBadgeSize.small,
                      textStyle: AppText.title(AppColors.textPrimary),
                    ),
                  ),
                  if (admin.primaryBadge != null) ...[
                    AppSpace.wGapSm,
                    BadgeIcon(
                      badge: admin.primaryBadge!,
                      size: BadgeSize.small,
                      showTooltip: false,
                    ),
                  ],
                ],
              ),
              if (handle != null) ...[
                AppSpace.gapHair,
                Text(
                  handle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(AppColors.textMuted,
                      weight: AppText.regular),
                ),
              ],
              if (role != null) ...[
                AppSpace.gapSm,
                ProfilePill(
                  label: publicProfileRoleLabel(role),
                  color: publicProfileRoleColor(role),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
