import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:flutter/material.dart';

/// The small parts of a feed card, drawn in the app's original flat style:
/// thin outlines, light tints, small uppercase labels.

/// The author's level, as a small tier-coloured disc showing the number. It
/// sits in front of the name, where the old feed put the level icon.
class FeedLevelBadge extends StatelessWidget {
  const FeedLevelBadge({super.key, required this.level});

  final UserLevelModel level;

  @override
  Widget build(BuildContext context) {
    final tier = LevelTier.forLevel(level.level);
    return Container(
      width: AppIcon.sm,
      height: AppIcon.sm,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tier.fallbackColor,
      ),
      child: Text(
        '${level.level}',
        style: AppTypography.custom(
          color: AppColors.bgBase,
          size: 9,
          weight: FontWeight.w700,
        ).copyWith(height: 1),
      ),
    );
  }
}

/// `LOW` / `MEDIUM` / `HIGH`, as the old outlined pill tinted with the
/// priority's own colour.
class FeedPriorityTag extends StatelessWidget {
  const FeedPriorityTag({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final color = priority.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.hair,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: AppTypography.custom(
          color: color,
          size: AppText.captionSize,
          weight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// The gem line: a layers icon and "in" plus the gem name, with the priority
/// pill at the far right. Tapping the line opens the gem.
class FeedProjectTag extends StatelessWidget {
  const FeedProjectTag({
    super.key,
    required this.project,
    required this.priority,
    required this.onTap,
  });

  final Project project;
  final Priority priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            Icons.layers_outlined,
            size: AppIcon.xs,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: AppSpace.xs + 2),
          Expanded(
            child: Text(
              'in ${project.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          FeedPriorityTag(priority: priority),
        ],
      ),
    );
  }
}

/// Edge's read on a gem: a small outlined chip with how many signals and what
/// it recommends. Only `act` takes the accent colour.
class FeedEdgeTag extends StatelessWidget {
  const FeedEdgeTag({
    super.key,
    required this.signals,
    required this.verdict,
  });

  final int signals;
  final String verdict;

  bool get _isAct => verdict.toLowerCase() == 'act';

  @override
  Widget build(BuildContext context) {
    final accent = _isAct ? AppColors.primary400 : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.hair,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: AppIcon.xs, color: accent),
          const SizedBox(width: AppSpace.xs),
          Text(
            'EDGE · $signals ${signals == 1 ? 'signal' : 'signals'}',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            verdict.toUpperCase(),
            style: AppTypography.custom(
              color: accent,
              size: AppText.captionSize,
              weight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
