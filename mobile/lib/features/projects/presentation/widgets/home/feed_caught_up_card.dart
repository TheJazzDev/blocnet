import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

/// Shown when nothing a member follows needs them.
///
/// Drawn as the app's original Alpha Radar panel: a small header, the
/// headline, one sentence, and the receipt as a single muted line — what was
/// checked, across how many gems, and how recently. Reassurance that shows its
/// work is what lets someone stop checking.
///
/// Every number here is one the app actually knows. There is deliberately no
/// "unread" count: nothing tracks per-update reads, so claiming one would be
/// inventing a figure to fill a slot.
class FeedCaughtUpCard extends StatelessWidget {
  const FeedCaughtUpCard({
    super.key,
    required this.accent,
    required this.gemsFollowed,
    required this.updatesTracked,
    required this.sweptAt,
  });

  final Color accent;

  /// How many gems the member follows. Zero is handled by the day-one feed
  /// instead, so this card is never shown for an empty board.
  final int gemsFollowed;

  /// Updates currently on the member's board across those gems.
  final int updatesTracked;

  /// When the radar last swept. Null when the summary has not arrived.
  final DateTime? sweptAt;

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomePanelHeader(
            icon: Icons.radar_rounded,
            label: 'ALPHA RADAR',
            iconColor: accent,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            "You're all caught up",
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _subtitle,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            _receipt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.labelSize,
              weight: FontWeight.w500,
            ).merge(AppText.tabular),
          ),
        ],
      ),
    );
  }

  String get _receipt {
    final gems = '$gemsFollowed ${gemsFollowed == 1 ? 'gem' : 'gems'}';
    final updates =
        '$updatesTracked ${updatesTracked == 1 ? 'update' : 'updates'}';
    final sweep =
        'last sweep ${sweptAt == null ? '—' : getTimeStamp(sweptAt!)}';
    return '$gems · $updates · $sweep';
  }

  String get _subtitle {
    if (gemsFollowed == 1) {
      return 'Nothing needs you on the one gem you follow. '
          'Its hunter is keeping it current.';
    }
    return 'Nothing needs you across the $gemsFollowed gems on your board. '
        'A hunter is keeping each one current.';
  }
}
