import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_pill.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_avatar.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_level_pill.dart';
import 'package:flutter/material.dart';

/// Avatar, name, handle, pills (space, role, level), bio and earned badges,
/// left-aligned on the page ground, with an Edit button. Everyone.
class ProfileHeroSection extends StatelessWidget {
  const ProfileHeroSection({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.handle,
    required this.bio,
    required this.activeSpace,
    required this.isHunter,
    required this.onEditTap,
    this.badges = const [],
    this.primaryBadge,
    this.currentLevel,
  });

  final String displayName;
  final String? avatarUrl;

  /// `@username`, or the email when there is no username.
  final String? handle;
  final String? bio;
  final SpaceMeta activeSpace;

  /// Adds the HUNTER role pill.
  final bool isHunter;
  final VoidCallback onEditTap;
  final List<BadgeModel> badges;
  final BadgeModel? primaryBadge;
  final UserLevelModel? currentLevel;

  @override
  Widget build(BuildContext context) {
    final normalizedBio = bio?.trim() ?? '';
    final shownBadges =
        badges.isNotEmpty ? badges : [if (primaryBadge != null) primaryBadge!];
    void openBadges() => Navigator.of(context).pushNamed(AppRoutes.badges);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                name: displayName,
                imageUrl: avatarUrl,
                size: 56,
              ),
              AppSpace.wGapMd,
              Expanded(child: _identity()),
              AppSpace.wGapSm,
              _EditButton(onTap: onEditTap),
            ],
          ),
          if (normalizedBio.isNotEmpty) ...[
            AppSpace.gapMd,
            Text(
              normalizedBio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  AppText.body(AppColors.textSecondary).copyWith(height: 1.45),
            ),
          ],
          if (shownBadges.isNotEmpty) ...[
            AppSpace.gapMd,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final badge in shownBadges)
                  BadgeIcon(
                    badge: badge,
                    size: BadgeSize.small,
                    showTooltip: false,
                    onTap: openBadges,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.title(AppColors.textPrimary),
        ),
        if (handle?.trim().isNotEmpty ?? false) ...[
          AppSpace.gapHair,
          Text(
            handle!.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(AppColors.textMuted, weight: AppText.regular),
          ),
        ],
        AppSpace.gapSm,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ProfilePill(
              label: activeSpace.label,
              color: activeSpace.accent,
              icon: activeSpace.icon,
            ),
            if (isHunter)
              const ProfilePill(
                label: 'Hunter',
                color: AppColors.tagPartnership,
              ),
            if (currentLevel != null)
              ProfileLevelPill(level: currentLevel!, maxNameWidth: 110),
          ],
        ),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('profile-edit'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 36),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        side: const BorderSide(color: AppColors.borderMuted),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        foregroundColor: AppColors.textPrimary,
      ),
      icon: Icon(Icons.edit_outlined,
          size: AppIcon.xs, color: AppColors.textMuted),
      label: Text(
        'Edit',
        style: AppText.label(AppColors.textPrimary, weight: AppText.semibold),
      ),
    );
  }
}
