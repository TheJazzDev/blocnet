import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_dialog.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

enum GemCardLayout { card, list }

class GemCard extends StatelessWidget {
  const GemCard({
    super.key,
    required this.project,
    required this.isFollowed,
    required this.onFollowToggle,
    required this.isLoading,
    this.layout = GemCardLayout.card,
    this.hypeScore,
    this.onPreferencesTap,
    this.onManageTap,
  });

  final Project project;
  final bool isFollowed;
  final VoidCallback onFollowToggle;
  final bool isLoading;
  final GemCardLayout layout;
  final double? hypeScore;
  final VoidCallback? onPreferencesTap;
  final VoidCallback? onManageTap;

  void _openDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectDetailsDialog(projectId: project.id);
      },
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  /// Derives a hype score 0-10 from followers + update count.
  double _deriveHypeScore() {
    final followers = project.followersCount;
    final updates = project.posts?.length ?? 0;
    final raw = (followers * 0.05 + updates * 0.3).clamp(0.0, 10.0);
    return double.parse(raw.toStringAsFixed(1));
  }

  Color _scoreColor(double score) {
    if (score >= 7) return AppColors.hypeHigh;
    if (score >= 4) return AppColors.hypeMid;
    return AppColors.hypeLow;
  }

  void _openHunterProfile(BuildContext context) {
    final hunter = project.admin;
    if (hunter == null) return;
    PublicProfileScreen.showSheet(context, hunter);
  }

  Widget _buildListLayout(
    BuildContext context,
    double score,
    Color scoreColor,
  ) {
    final admin = project.admin;
    return InkWell(
      onTap: () => _openDetails(context),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.2),
                    AppColors.primary500.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.25),
                ),
              ),
              child: project.logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        project.logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.layers_outlined,
                          size: AppIcon.md,
                          color: AppColors.primary400,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.layers_outlined,
                      size: AppIcon.md,
                      color: AppColors.primary400,
                    ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: AppText.bodySize,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      // Label the score so the decimal is not a mystery
                      // number in list mode (grid mode has the HYPE SCORE bar).
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            score.toStringAsFixed(1),
                            style: AppTypography.custom(
                              color: scoreColor,
                              size: AppText.labelSize,
                              weight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          Text(
                            'hype',
                            style: AppTypography.custom(
                              color: AppColors.textFaint,
                              size: AppText.captionSize,
                              weight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '${project.primaryTag.name} • ${project.followersCount} followers • ${project.posts?.length ?? 0} updates',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: AppText.captionSize,
                      weight: FontWeight.w500,
                    ),
                  ),
                  if (project.description.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      project.description.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (admin != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    GestureDetector(
                      onTap: () => _openHunterProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          AppAvatar(
                            radius: 9,
                            imageUrl: admin.imageUrl,
                            backgroundColor: AppColors.bgSurface,
                            fallback: Icon(
                              Icons.person,
                              size: AppIcon.xs,
                              color: AppColors.textFaint,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Hunted by ',
                                  style: AppTypography.custom(
                                    color: AppColors.textMuted,
                                    size: AppText.captionSize,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Flexible(
                                  child: UserNameWithLevelIcon(
                                    name: admin.name,
                                    currentLevel: admin.currentLevel,
                                    levelBadgeSize: LevelBadgeSize.tiny,
                                    textStyle: AppTypography.custom(
                                      color: AppColors.textMuted,
                                      size: AppText.captionSize,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.translucent,
              child: GestureDetector(
                onTap: isLoading ? null : onFollowToggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isLoading ? 0.6 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isFollowed
                          ? AppColors.primary500.withValues(alpha: 0.18)
                          : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(AppRadius.fullValue),
                      border: Border.all(
                        color: isFollowed
                            ? AppColors.primary500.withValues(alpha: 0.45)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      isFollowed ? 'Following' : 'Follow',
                      style: AppTypography.custom(
                        color: isFollowed
                            ? AppColors.primary400
                            : AppColors.textFaint,
                        size: AppText.captionSize,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = hypeScore ?? _deriveHypeScore();
    final scoreColor = _scoreColor(score);
    final admin = project.admin;

    if (layout == GemCardLayout.list) {
      return _buildListLayout(context, score, scoreColor);
    }

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Stack(
        children: [
          // Glow effect based on hype score
          Positioned(
            right: -30,
            top: 10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scoreColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main card
          Container(
            margin: const EdgeInsets.only(bottom: AppSpace.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgSurface,
                  AppColors.bgSurface.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xlValue),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: logo + name + hype score ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo with gradient border
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary500.withValues(alpha: 0.25),
                              AppColors.primary500.withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lgValue),
                          border: Border.all(
                            color: AppColors.primary500.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: project.logo.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                                child: Image.network(
                                  project.logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.layers_outlined,
                                    size: AppIcon.lg,
                                    color: AppColors.primary400,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.layers_outlined,
                                size: AppIcon.lg,
                                color: AppColors.primary400,
                              ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      // Name + tag
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: AppTypography.custom(
                                color: AppColors.textPrimary,
                                size: AppText.subtitleSize,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.tag_rounded,
                                  size: AppIcon.xs,
                                  color: AppColors.textFaint,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  project.primaryTag.name,
                                  style: AppTypography.custom(
                                    color: AppColors.textFaint,
                                    size: AppText.captionSize,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.sm,
                                    vertical: AppSpace.hair,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.teal400
                                            .withValues(alpha: 0.2),
                                        AppColors.teal500
                                            .withValues(alpha: 0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppRadius.smValue),
                                    border: Border.all(
                                      color: AppColors.teal400
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'GEM',
                                    style: AppTypography.custom(
                                      color: AppColors.teal400,
                                      size: AppText.captionSize,
                                      weight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpace.lg),

                  // ── Hype score bar ──
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scoreColor.withValues(alpha: 0.08),
                          scoreColor.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.whatshot_rounded,
                          size: AppIcon.sm,
                          color: scoreColor,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          'HYPE SCORE',
                          style: AppTypography.custom(
                            color: AppColors.textFaint,
                            size: AppText.captionSize,
                            weight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: SizedBox(
                            height: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.fullValue),
                              child: Stack(
                                children: [
                                  Container(color: AppColors.bgElevated),
                                  FractionallySizedBox(
                                    widthFactor: (score / 10).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            scoreColor,
                                            scoreColor.withValues(alpha: 0.7)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Text(
                          score.toStringAsFixed(1),
                          style: AppTypography.custom(
                            color: scoreColor,
                            size: AppText.bodySize,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.md),

                  // ── Hunted by row ──
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.bgElevated.withValues(alpha: 0.8),
                          AppColors.bgElevated.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                      border: Border.all(
                        color: AppColors.borderSubtle.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _openHunterProfile(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppColors.primary500.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: AppAvatar(
                              radius: 13,
                              imageUrl: admin?.imageUrl,
                              backgroundColor: AppColors.bgSurface,
                              fallback: Icon(
                                Icons.person,
                                size: AppIcon.sm,
                                color: AppColors.textFaint,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openHunterProfile(context),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Text(
                                  'Hunted by ',
                                  style: AppTypography.custom(
                                    color: AppColors.textSecondary,
                                    size: AppText.labelSize,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Flexible(
                                  child: UserNameWithLevelIcon(
                                    name: admin?.name ?? 'Unknown',
                                    currentLevel: admin?.currentLevel,
                                    levelBadgeSize: LevelBadgeSize.tiny,
                                    textStyle: AppTypography.custom(
                                      color: AppColors.textPrimary,
                                      size: AppText.labelSize,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.trending_up_rounded,
                          size: AppIcon.sm,
                          color: AppColors.successColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.md),

                  // ── Action row ──
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.translucent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onManageTap != null) ...[
                          GestureDetector(
                            onTap: onManageTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md,
                                vertical: AppSpace.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: AppIcon.sm,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpace.xs),
                                  Text(
                                    'Manage',
                                    style: AppTypography.custom(
                                      color: AppColors.textSecondary,
                                      size: AppText.labelSize,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                        ],
                        if (isFollowed && onPreferencesTap != null) ...[
                          GestureDetector(
                            onTap: onPreferencesTap,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpace.md),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary500.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                                border: Border.all(
                                  color: AppColors.primary500
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                size: AppIcon.sm,
                                color: AppColors.primary400,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                        ],
                        GestureDetector(
                          onTap: isLoading ? null : onFollowToggle,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: isLoading ? 0.6 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.lg,
                                vertical: AppSpace.md,
                              ),
                              decoration: BoxDecoration(
                                gradient: isFollowed
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.primary500
                                              .withValues(alpha: 0.2),
                                          AppColors.primary500
                                              .withValues(alpha: 0.15),
                                        ],
                                      )
                                    : null,
                                color: isFollowed ? null : AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                                border: Border.all(
                                  color: isFollowed
                                      ? AppColors.primary500
                                          .withValues(alpha: 0.5)
                                      : AppColors.borderSubtle,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFollowed
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: AppIcon.sm,
                                    color: isFollowed
                                        ? AppColors.primary400
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Text(
                                    isFollowed ? 'Following' : 'Follow',
                                    style: AppTypography.custom(
                                      color: isFollowed
                                          ? AppColors.primary400
                                          : AppColors.textSecondary,
                                      size: AppText.labelSize,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
