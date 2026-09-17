import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_status_pill.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_parts.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_role_chip.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// The author's avatar, the left column of a community post or comment.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.author,
    required this.onTap,
    this.radius = 20,
  });

  final Admin? author;
  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = communityDisplayName(author);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppAvatar(
        radius: radius,
        imageUrl: author?.imageUrl,
        fallback: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: AppTypography.custom(
            color: AppColors.primary400,
            size: radius >= 20 ? AppText.subtitleSize : AppText.bodySize,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Who wrote it: level, name, role pill and time on one line, the handle (and
/// any moderation status) beneath. [trailing] sits at the end of the top line,
/// usually the ⋯ menu.
class CommunityAuthorLine extends StatelessWidget {
  const CommunityAuthorLine({
    super.key,
    required this.author,
    required this.createdAt,
    required this.onTap,
    this.status = CommunityContentModerationStatus.active,
    this.trailing,
  });

  final Admin? author;
  final DateTime createdAt;
  final VoidCallback onTap;
  final CommunityContentModerationStatus status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final roleLabel = author?.displayRoleLabel;
    final level = author?.currentLevel;
    final name = communityDisplayName(author);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: LayoutBuilder(
                  builder: (context, constraints) => _NameRow(
                    name: name,
                    level: level,
                    roleLabel: roleLabel,
                    maxWidth: constraints.maxWidth,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              getTimeStamp(createdAt),
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w400,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpace.hair),
        Row(
          children: [
            Flexible(
              child: Text(
                communityHandle(author),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.labelSize,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            if (status != CommunityContentModerationStatus.active) ...[
              const SizedBox(width: AppSpace.sm),
              CommunityStatusPill(status: status),
            ],
          ],
        ),
      ],
    );
  }
}

/// Level, name and role pill. On a narrow line the name keeps a readable
/// minimum: the role pill goes first, then the level, rather than overflow.
class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.name,
    required this.level,
    required this.roleLabel,
    required this.maxWidth,
  });

  static const double _minName = 56;
  static const double _badgeWidth = AppIcon.sm + AppSpace.xs + 2;

  final String name;
  final UserLevelModel? level;
  final String? roleLabel;
  final double maxWidth;

  double _chipWidth(String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: AppText.captionSize,
          weight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    // Chip padding and border, plus the gap before it.
    return width + (AppSpace.xs + 2) * 2 + 2 + AppSpace.sm;
  }

  @override
  Widget build(BuildContext context) {
    final label = roleLabel;
    final chipWidth = label == null ? 0.0 : _chipWidth(label);
    final showChip = label != null && maxWidth - chipWidth >= _minName;
    final used = showChip ? chipWidth : 0.0;
    final showLevel =
        level != null && maxWidth - used - _badgeWidth >= _minName;

    return Row(
      children: [
        if (showLevel) ...[
          FeedLevelBadge(level: level!),
          const SizedBox(width: AppSpace.xs + 2),
        ],
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w700,
            ),
          ),
        ),
        if (showChip) ...[
          const SizedBox(width: AppSpace.sm),
          FeedRoleChip(label: label, color: FeedRoleChip.colorFor(label)),
        ],
      ],
    );
  }
}

/// The small ⋯ button at the end of an author line.
class CommunityMoreButton extends StatelessWidget {
  const CommunityMoreButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'More options',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpace.sm),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              Icons.more_horiz_rounded,
              size: AppIcon.md,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

String communityDisplayName(Admin? author) {
  final name = author?.name.trim() ?? '';
  return name.isNotEmpty ? name : 'Blocnet member';
}

String communityHandle(Admin? author) {
  final raw = author?.username.trim().replaceAll('@', '') ?? '';
  if (raw.isNotEmpty) return '@$raw';
  final id = author?.id ?? '';
  if (id.isEmpty) return '@member';
  return '@${id.substring(0, id.length >= 6 ? 6 : id.length)}';
}
