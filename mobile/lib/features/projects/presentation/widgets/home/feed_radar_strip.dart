import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

/// What the radar found, above the feed.
///
/// Drawn as the app's original Alpha Radar panel: a small header carrying the
/// sweep time, then one line — what arrived, and across how many gems. It
/// replaces the separate Alpha Radar and Edge Engine panels the screen used to
/// stack, so the first real post stays near the top.
///
/// When nothing is waiting the strip is not shown at all — `FeedCaughtUpCard`
/// takes its place.
class FeedRadarStrip extends StatelessWidget {
  const FeedRadarStrip({
    super.key,
    required this.radar,
    required this.accent,
  });

  final RadarSummary radar;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final high = radar.highUrgencyCount;
    final isUrgent = high > 0;
    final gems = radar.activeProjects.length;

    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomePanelHeader(
            icon: Icons.radar_rounded,
            label: 'ALPHA RADAR',
            // The mark turns red when something is urgent, rather than the
            // whole line changing colour.
            iconColor: isUrgent ? AppColors.priorityHigh : accent,
            trailing: Text(
              'swept ${getTimeStamp(radar.asOf)}',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: isUrgent
                      ? '$high high priority'
                      : '${radar.newUpdatesCount} new',
                  style: AppTypography.custom(
                    color: isUrgent
                        ? AppColors.priorityHigh
                        : AppColors.textPrimary,
                    size: AppText.bodySize,
                    weight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: isUrgent
                      ? _wherePhrase()
                      : ' across $gems ${gems == 1 ? 'gem' : 'gems'}',
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Names the gem when the urgency is all in one place ("1 high priority in
  /// Core Mines").
  String _wherePhrase() {
    final withHigh =
        radar.activeProjects.where((p) => p.highCount > 0).toList();
    if (withHigh.length == 1) return ' in ${withHigh.first.projectName}';
    if (withHigh.isEmpty) return '';
    return ' across ${withHigh.length} gems';
  }
}
