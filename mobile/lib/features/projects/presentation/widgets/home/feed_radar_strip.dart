import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

/// What the radar found, as one line above the feed.
///
/// Reference: `.rstrip` in `docs/artifacts/blocnet-home-feed-v2.html`.
///
/// This replaces two full cards the screen used to stack above every feed —
/// an Alpha Radar panel and a Blocnet Edge Engine panel — neither of which
/// exists anywhere in the approved design. Between them they pushed the first
/// real post most of a screen down, which is the problem the redesign started
/// from. The design's answer is a single 13px line: what arrived, across how
/// many gems, and when the sweep ran.
///
/// When nothing is waiting the strip is not shown at all — `FeedCaughtUpCard`
/// takes its place, which is why the design's caught-up state has no strip.
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      child: Row(
        children: [
          // A live dot when something is urgent, the radar mark otherwise —
          // the design swaps these rather than colouring the whole line.
          if (isUrgent)
            _PulseDot(color: AppColors.priorityHigh)
          else
            Icon(Icons.radar_rounded, size: AppIcon.sm, color: accent),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: isUrgent
                        ? '$high high priority'
                        : '${radar.newUpdatesCount} new',
                    style: AppTypography.custom(
                      color: isUrgent
                          ? const Color(0xFFFCA5A5)
                          : AppColors.textSecondary,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: isUrgent
                        ? _wherePhrase()
                        : ' across $gems ${gems == 1 ? 'gem' : 'gems'}',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.labelSize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            'swept ${getTimeStamp(radar.asOf)}',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Names the gem when the urgency is all in one place, which is the case
  /// the design writes out ("1 high priority in Core Mines").
  String _wherePhrase() {
    final withHigh =
        radar.activeProjects.where((p) => p.highCount > 0).toList();
    if (withHigh.length == 1) return ' in ${withHigh.first.projectName}';
    if (withHigh.isEmpty) return '';
    return ' across ${withHigh.length} gems';
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
