import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/quiet_gem.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_quiet_gem_parts.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// A card in the feed, authored by Blocnet, saying that a gem the member
/// follows has gone quiet.
///
/// It sits in the stream where the missing update would have been, rather than
/// in a separate screen or mode — the failure of the promise belongs in the
/// same place the promise is normally kept. The hunter's last words are quoted,
/// so the member sees what they are waiting on rather than only being told
/// something is wrong.
///
/// Desaturated, not alarmed. The card is a plain panel and red appears only
/// on Report: a hunter who has gone quiet is a lapse to be stated, not a
/// moderation event. It also claims only what is knowable — that nothing has
/// come through, never that the project is dead.
///
/// All three actions are live. *Ask* is a nudge to the hunter, aggregated
/// server-side so thirty-one members asking reaches them as one notification
/// carrying the count. *Report* is an escalation to a moderator and does not
/// reassign the gem — taking coverage from a hunter stays a decision a person
/// makes. *Unfollow* is the member's own exit.
///
/// Report is separated from the other two and coloured, because it is the one
/// that puts another member's standing in question. It is the only red on an
/// otherwise deliberately grey card.
class FeedQuietGemCard extends StatelessWidget {
  const FeedQuietGemCard({
    super.key,
    required this.gem,
    required this.onUnfollow,
    required this.onAsk,
    required this.onReport,
  });

  final QuietGem gem;
  final VoidCallback onUnfollow;
  final VoidCallback onAsk;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final handle = gem.hunterHandle;
    final last = gem.lastUpdate;

    return HomePanel(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blocnet is the author here, so the avatar is a system mark
              // rather than a person's face.
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgElevated,
                ),
                child: Icon(
                  Icons.running_with_errors_rounded,
                  size: AppIcon.sm,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No word on ${gem.project.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      handle == null
                          ? 'Untouched for ${gem.daysSilent} days'
                          : '$handle last posted ${gem.daysSilent} days ago',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: AppText.labelSize,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'You follow this gem, but nothing has come through. '
            'Blocnet cannot tell you what the project is doing now — only '
            'that nobody has reported it.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          if (last != null) ...[
            const SizedBox(height: AppSpace.md),
            QuietGemLastWords(update: last, daysAgo: gem.daysSilent),
          ],
          const SizedBox(height: AppSpace.md),
          QuietGemButton(
            icon: Icons.campaign_outlined,
            label: handle == null
                ? 'Ask for an update'
                : 'Ask $handle for an update',
            onTap: onAsk,
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: QuietGemButton(
                  icon: Icons.visibility_off_outlined,
                  label: 'Unfollow',
                  onTap: onUnfollow,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: QuietGemButton(
                  icon: Icons.flag_outlined,
                  label: 'Report inactive',
                  onTap: onReport,
                  danger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Reported gems go to a moderator, who decides whether to '
            'reassign them.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
