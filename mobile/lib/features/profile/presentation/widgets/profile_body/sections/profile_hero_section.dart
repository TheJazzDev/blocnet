import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_level_pill.dart';
import 'package:flutter/material.dart';

/// Avatar, name, email, bio, earned badges, level pill and the active
/// space label. Shown to every user regardless of roles or active space.
class ProfileHeroSection extends StatelessWidget {
  const ProfileHeroSection({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.email,
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
  final String? email;
  final String? bio;
  final SpaceMeta activeSpace;

  /// Adds the verified hunter mark on the avatar.
  final bool isHunter;
  final VoidCallback onEditTap;
  final List<BadgeModel> badges;
  final BadgeModel? primaryBadge;
  final UserLevelModel? currentLevel;

  @override
  Widget build(BuildContext context) {
    final normalizedBio = bio?.trim() ?? '';

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  activeSpace.accent.withValues(alpha: 0.12),
                  AppColors.teal500.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                displayName: displayName,
                avatarUrl: avatarUrl,
                showVerifiedMark: isHunter,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTypography.custom(
                              color: AppColors.textPrimary,
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (primaryBadge != null && badges.isEmpty) ...[
                          const SizedBox(width: 6),
                          BadgeIcon(
                            badge: primaryBadge!,
                            size: BadgeSize.medium,
                            showTooltip: false,
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.badges),
                          ),
                        ],
                      ],
                    ),
                    if (email?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        email!.trim(),
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 10,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (normalizedBio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        normalizedBio,
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 11,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final badge in badges)
                            BadgeIcon(
                              badge: badge,
                              size: BadgeSize.small,
                              showTooltip: false,
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.badges),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _SpaceLabel(space: activeSpace),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 0,
          child: GestureDetector(
            onTap: onEditTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppColors.primary400,
              ),
            ),
          ),
        ),
        if (currentLevel != null)
          Positioned(
            right: 16,
            top: 14,
            child: ProfileLevelPill(level: currentLevel!),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.displayName,
    required this.avatarUrl,
    required this.showVerifiedMark,
  });

  final String displayName;
  final String? avatarUrl;
  final bool showVerifiedMark;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl?.trim().isNotEmpty == true;

    Widget fallback() => Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: AppTypography.custom(
            color: AppColors.teal400,
            size: 22,
            weight: FontWeight.w800,
          ),
        );

    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal400, AppColors.primary500],
            ),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgBase,
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Container(
                color: AppColors.bgElevated,
                child: hasAvatar
                    ? Image.network(
                        avatarUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Center(child: fallback()),
                      )
                    : Center(child: fallback()),
              ),
            ),
          ),
        ),
        if (showVerifiedMark)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary400, AppColors.primary500],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgBase, width: 2.5),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 12,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}

class _SpaceLabel extends StatelessWidget {
  const _SpaceLabel({required this.space});

  final SpaceMeta space;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: space.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(space.icon, size: 10, color: space.accent),
          const SizedBox(width: 4),
          Text(
            '${space.label} Space',
            style: AppTypography.custom(
              color: space.accent,
              size: 9,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
