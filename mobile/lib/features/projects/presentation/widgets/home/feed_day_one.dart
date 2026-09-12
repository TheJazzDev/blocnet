import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:flutter/material.dart';

/// What Home says to a member who follows nothing.
///
/// The zero-follow case used to be an empty state, and round six is emphatic
/// that it must not be: Home borrows Discover's job while the board is empty,
/// so the screen is browsable and specific on day one rather than a form to
/// fill in. The blend already keeps real posts flowing (see `FeedBlend`); this
/// is the part that says *why* and gives somewhere to start.
///
/// Shown only at zero follows. The moment a member follows their first gem it
/// disappears, because from then on the feed speaks for itself.
class FeedDayOneIntro extends StatelessWidget {
  const FeedDayOneIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Pick the projects you're farming. ",
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.bodySize,
                weight: FontWeight.w700,
                height: 1.55,
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
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled divider between stretches of the day-one feed.
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
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm, color: accent),
          const SizedBox(width: AppSpace.sm),
          Text(
            label,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.subtitleSize,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One gem a member could follow, with everything needed to decide: the chain,
/// how many people already follow it, and who covers it.
class FeedFollowRow extends StatelessWidget {
  const FeedFollowRow({
    super.key,
    required this.project,
    required this.accent,
    required this.isFollowed,
    required this.onToggleFollow,
    required this.onOpen,
  });

  final Project project;
  final Color accent;
  final bool isFollowed;
  final VoidCallback onToggleFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hunter = project.admin?.username.trim();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      child: InkWell(
        onTap: onOpen,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              _Monogram(name: project.name, accent: accent),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.bodySize,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      _subtitle(hunter),
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
              const SizedBox(width: AppSpace.sm),
              _FollowButton(
                accent: accent,
                isFollowed: isFollowed,
                onTap: onToggleFollow,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(String? hunter) {
    final chain = project.primaryTag.name;
    final followers = project.followersCount;
    final people = followers == 1 ? '1 following' : '$followers following';
    if (hunter == null || hunter.isEmpty) return '$chain · $people';
    final handle = hunter.startsWith('@') ? hunter : '@$hunter';
    return '$chain · $people · $handle';
  }
}

/// The gem's initials, standing in until real project logos ship.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'
        : name.trim().isEmpty
            ? '?'
            : name.trim().substring(0, name.trim().length >= 2 ? 2 : 1);

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        initials.toUpperCase(),
        style: AppTypography.custom(
          color: accent,
          size: AppText.labelSize,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.accent,
    required this.isFollowed,
    required this.onTap,
  });

  final Color accent;
  final bool isFollowed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36, minWidth: 76),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.full,
          // Following is the settled state, so it fills; Follow is the
          // invitation, so it outlines.
          color: isFollowed ? accent.withValues(alpha: 0.16) : null,
          border: Border.all(
            color: accent.withValues(alpha: isFollowed ? 0.0 : 0.36),
          ),
        ),
        child: Text(
          isFollowed ? 'Following' : 'Follow',
          style: AppTypography.custom(
            color: accent,
            size: AppText.labelSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
