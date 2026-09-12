import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/quiet_gem.dart';
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
/// Desaturated, not alarmed. The card is grey throughout and red appears on
/// nothing here: a hunter who has gone quiet is a lapse to be stated, not a
/// moderation event. It also claims only what is knowable — that nothing has
/// come through, never that the project is dead.
///
/// **Read-only for now.** The design also offers *Ask for an update* and
/// *Report inactive*, and neither endpoint exists in the backend (F-42), so
/// they are absent rather than present and dead. Unfollow ships because
/// `ProjectsStore.toggleFollowProject` is real.
class FeedQuietGemCard extends StatelessWidget {
  const FeedQuietGemCard({
    super.key,
    required this.gem,
    required this.onUnfollow,
  });

  final QuietGem gem;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    final handle = gem.hunterHandle;
    final last = gem.lastUpdate;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        border: Border(
          left: BorderSide(color: Color(0xFF52525b), width: 3),
          bottom: BorderSide(color: AppColors.borderFaint),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md - 3,
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
        ),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgSurface,
                    border: Border.all(color: AppColors.borderSubtle),
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
              _LastWords(update: last, daysAgo: gem.daysSilent),
            ],
            const SizedBox(height: AppSpace.md),
            // One action, because one action is real. See the class doc.
            _GhostButton(
              icon: Icons.visibility_off_outlined,
              label: 'Unfollow ${gem.project.name}',
              onTap: onUnfollow,
            ),
          ],
        ),
      ),
    );
  }
}

/// The hunter's last update, quoted. Shows the member what they are waiting
/// on, which is more useful than a bare "no updates" line.
class _LastWords extends StatelessWidget {
  const _LastWords({required this.update, required this.daysAgo});

  final Update update;
  final int daysAgo;

  @override
  Widget build(BuildContext context) {
    final title = update.title.trim();
    final body = update.description.trim();
    final quoted = title.isNotEmpty ? title : body;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST UPDATE · $daysAgo DAYS AGO',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '"$quoted"',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIcon.sm, color: AppColors.textSecondary),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
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
