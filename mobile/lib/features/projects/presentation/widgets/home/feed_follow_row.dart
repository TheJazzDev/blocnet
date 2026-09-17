import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:flutter/material.dart';

/// One gem a member could follow, with everything needed to decide: the chain,
/// how many people already follow it, and who covers it.
///
/// Drawn like the old Discover list: a small tinted tile, name and meta line,
/// and a quiet filled Follow button, separated from the next row by a divider.
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
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: InkWell(
        onTap: onOpen,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
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
                        color: AppColors.textFaint,
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

/// The gem's initials on a small tinted tile, standing in until real project
/// logos ship.
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
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: accent.withValues(alpha: 0.08),
      ),
      child: Text(
        initials.toUpperCase(),
        style: AppTypography.custom(
          color: accent,
          size: AppText.labelSize,
          weight: FontWeight.w700,
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
        constraints: const BoxConstraints(minHeight: 32, minWidth: 72),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.full,
          // Follow is the quiet filled button the old list used; Following
          // takes the accent so the settled state is recognisable.
          color: isFollowed
              ? accent.withValues(alpha: 0.12)
              : AppColors.bgElevated,
        ),
        child: Text(
          isFollowed ? 'Following' : 'Follow',
          style: AppTypography.custom(
            color: isFollowed ? accent : AppColors.textSecondary,
            size: AppText.labelSize,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
