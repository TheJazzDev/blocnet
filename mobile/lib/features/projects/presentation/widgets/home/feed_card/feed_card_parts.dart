import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:flutter/material.dart';

/// The small parts of a feed card, each built to the approved round-six design
/// rather than adapted from what the screen happened to have.
///
/// Reference: `docs/artifacts/blocnet-home-feed-v2.html`, the "card at rest"
/// and "urgent" panels. Where a measurement is quoted below it comes from that
/// file, not from taste.

/// The author's level, as an 18px tier-coloured disc showing the number.
///
/// The design's `.bdg` is a filled disc carrying the level **number**, tinted
/// by tier, sized to sit inside a line of 15px text. The app previously put the
/// full badge artwork here, which is the right thing on the levels screen and
/// too much detail at this size — in a feed row it reads as a smudge and costs
/// an SVG decode per card.
class FeedLevelBadge extends StatelessWidget {
  const FeedLevelBadge({super.key, required this.level});

  final UserLevelModel level;

  @override
  Widget build(BuildContext context) {
    final tier = LevelTier.forLevel(level.level);
    return Container(
      width: 18,
      height: 18,
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
          weight: FontWeight.w800,
        ).copyWith(height: 1),
      ),
    );
  }
}

/// `HUNTER`, `CORE TEAM`, `MODERATOR` — what the author is on this platform.
class FeedRoleTag extends StatelessWidget {
  const FeedRoleTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: color,
          size: AppText.captionSize,
          weight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// `LOW` / `MEDIUM` / `HIGH`, in the header row at the far right.
///
/// It belongs beside the author, not down on the project row where the app had
/// drifted to putting it: urgency is a property of what was said, so it reads
/// with who said it.
class FeedPriorityTag extends StatelessWidget {
  const FeedPriorityTag({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    // Low is neutral zinc: most updates are low, and a coloured pill on every
    // card would mean nothing. Only medium and high take their own colour.
    final isLow = priority.isLow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.bgElevated
            : priority.color.withValues(alpha: 0.15),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: AppTypography.custom(
          color: isLow ? AppColors.textFaint : priority.color,
          size: AppText.captionSize,
          weight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// The gem this update belongs to: a small inline pill carrying a round
/// monogram and the gem's name.
///
/// The app had this as a full-width gradient panel with a generic layers icon,
/// which made every card look like it contained a second card. The design's
/// version is one line, tinted by chain, and sized to the name.
class FeedProjectTag extends StatelessWidget {
  const FeedProjectTag({
    super.key,
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _chainTint(project.primaryTag.name);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, AppSpace.md, 4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.full,
          color: tint.withValues(alpha: 0.12),
          border: Border.all(color: tint.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
              child: Text(
                _monogram(project.name),
                style: AppTypography.custom(
                  color: AppColors.bgBase,
                  size: AppText.captionSize,
                  weight: FontWeight.w800,
                ).copyWith(height: 1),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edge's read on a gem: how many signals, and what it recommends.
///
/// Sits below the tags and takes colour only on `act`, so it can never compete
/// with a deadline on the same card. `ignore` is not drawn at all — a verdict
/// meaning "nothing to do" earns no space.
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
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.full,
        color: _isAct
            ? AppColors.primary400.withValues(alpha: 0.08)
            : AppColors.bgElevated,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar_rounded, size: AppIcon.xs, color: accent),
          const SizedBox(width: AppSpace.xs + 2),
          Text(
            'EDGE · $signals ${signals == 1 ? 'signal' : 'signals'}',
            style: AppTypography.custom(
              color: AppColors.textMuted,
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
              weight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

String _monogram(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  if (words.length >= 2) {
    return '${words.first[0]}${words.elementAt(1)[0]}'.toUpperCase();
  }
  final only = words.first;
  return only.substring(0, only.length >= 2 ? 2 : 1).toUpperCase();
}

/// Chain colours, matching the design's per-chain project tints. Categorical,
/// and deliberately independent of the brand accent.
Color _chainTint(String chain) {
  switch (chain.trim().toLowerCase()) {
    case 'core':
      return const Color(0xFFFB923C);
    case 'solana':
      return const Color(0xFF34D399);
    case 'ethereum':
      return const Color(0xFF818CF8);
    case 'telegram network':
      return const Color(0xFF38BDF8);
    case 'binance smart chain':
      return const Color(0xFFFBBF24);
    case 'ice open network':
      return const Color(0xFF2DD4BF);
    default:
      return AppColors.primary400;
  }
}
