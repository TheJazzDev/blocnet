import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Height of one [BadgeTile] in the gallery grid. Fixed rather than an
/// aspect ratio so a two-line name never overflows on a narrow phone.
const double kBadgeTileExtent = 172;

/// One badge in the gallery grid: a flat card, artwork top-left, name,
/// rarity pill and a one-line footer. Locked badges are dimmed.
class BadgeTile extends StatelessWidget {
  const BadgeTile({
    super.key,
    required this.badge,
    required this.isEarned,
    required this.isPrimary,
    this.earnedAt,
    this.onTap,
  });

  final BadgeModel badge;
  final bool isEarned;
  final bool isPrimary;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: isEarned ? 1 : 0.4,
                child: BadgeIcon(
                  badge: badge,
                  size: BadgeSize.large,
                  showTooltip: false,
                ),
              ),
              const Spacer(),
              _cornerMark(),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: Text(
              badge.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                isEarned ? AppColors.textPrimary : AppColors.textMuted,
                weight: AppText.bold,
              ).copyWith(height: 1.3),
            ),
          ),
          Opacity(
            opacity: isEarned ? 1 : 0.6,
            child: BadgeRarityChip(rarity: badge.rarity, compact: true),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _footer(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption(AppColors.textFaint),
          ),
        ],
      ),
    );
  }

  Widget _cornerMark() {
    if (isPrimary) {
      return AppPill(label: 'Primary', dense: true, uppercase: true);
    }
    return Icon(
      isEarned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
      size: AppIcon.sm,
      color: isEarned ? AppColors.successColor : AppColors.textFaint,
    );
  }

  String _footer() {
    if (!isEarned) return 'Unlocks at ${badge.pointsRequirement} pts';
    final at = earnedAt;
    if (at == null) return 'Earned';
    final month = at.month.toString().padLeft(2, '0');
    final day = at.day.toString().padLeft(2, '0');
    return 'Earned $month/$day/${at.year}';
  }
}
