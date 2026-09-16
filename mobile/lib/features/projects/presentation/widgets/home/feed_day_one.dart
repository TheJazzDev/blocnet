import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
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

/// The hunters worth following right now, shown on the day-one screen only.
///
/// Reference: `.hunters` in `docs/artifacts/blocnet-home-feed-v2.html`.
///
/// Three things differ from the rail the screen used to carry on every tab.
/// It appears **only at zero follows**, because once a member has a board the
/// people they follow are the feed and a row of strangers above it is noise.
/// It has no *View All* and no *My Updates* entry — the design's rail is five
/// hunters and nothing else, so the eye runs along one row of equal things.
/// And the avatars are lettered monograms rather than photos, which is what
/// makes the row read as a set instead of five unrelated pictures.
/// One hunter in the day-one rail. [admin] is what the profile sheet opens.
typedef FeedHunter = ({String handle, String name, Admin admin});

class FeedTopHunters extends StatelessWidget {
  const FeedTopHunters({
    super.key,
    required this.hunters,
    required this.onOpen,
  });

  /// Handle and display name per hunter, already ranked and capped by the
  /// caller.
  final List<FeedHunter> hunters;
  final void Function(Admin admin) onOpen;

  @override
  Widget build(BuildContext context) {
    if (hunters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding:
          const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, 0, AppSpace.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: AppIcon.xs,
                color: AppColors.textFaint,
              ),
              const SizedBox(width: AppSpace.xs + 2),
              Text(
                'TOP HUNTERS THIS WEEK',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: AppSpace.lg),
              itemCount: hunters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.lg),
              itemBuilder: (context, i) {
                final hunter = hunters[i];
                return _Hunter(
                  handle: hunter.handle,
                  name: hunter.name,
                  seed: i,
                  onTap: () => onOpen(hunter.admin),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Hunter extends StatelessWidget {
  const _Hunter({
    required this.handle,
    required this.name,
    required this.seed,
    required this.onTap,
  });

  final String handle;
  final String name;
  final int seed;
  final VoidCallback onTap;

  /// The design gives each hunter in the rail its own gradient, so five
  /// monograms read as five people rather than one repeated shape.
  static const _gradients = <List<Color>>[
    [Color(0xFF0891B2), Color(0xFF155E75)],
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFFEA580C), Color(0xFF7C2D12)],
    [Color(0xFF0D9488), Color(0xFF134E4A)],
    [Color(0xFFBE185D), Color(0xFF701A75)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[seed % _gradients.length];
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: Text(
                _initials(name, handle),
                style: AppTypography.custom(
                  color: Colors.white,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs + 2),
            Text(
              handle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name, String handle) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    final source = words.isNotEmpty ? words.first : handle.replaceAll('@', '');
    if (source.isEmpty) return '?';
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}
