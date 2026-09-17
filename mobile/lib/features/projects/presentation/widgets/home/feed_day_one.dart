import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

export 'feed_follow_row.dart';
export 'feed_top_hunters.dart';

/// What Home says to a member who follows nothing.
///
/// The zero-follow case must not be an empty state: Home borrows Discover's
/// job while the board is empty, so the screen is browsable and specific on
/// day one rather than a form to fill in. The blend already keeps real posts
/// flowing (see `FeedBlend`); this is the part that says *why* and gives
/// somewhere to start.
///
/// Shown only at zero follows. The moment a member follows their first gem it
/// disappears, because from then on the feed speaks for itself.
class FeedDayOneIntro extends StatelessWidget {
  const FeedDayOneIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Pick the projects you're farming. ",
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.bodySize,
                weight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            TextSpan(
              // States the promise in the member's terms, not the platform's:
              // what they get, not what the system does.
              text: 'A hunter covers each one and posts every time it moves, '
                  'so you hear it from them instead of finding out late.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section label between stretches of the day-one feed, in the app's small
/// uppercase style ("CURATED FEED", "TOP HUNTERS").
class FeedSectionHeading extends StatelessWidget {
  const FeedSectionHeading({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.xs),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.xs, color: accent),
          const SizedBox(width: AppSpace.xs + 2),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w600,
                letterSpacing: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
