import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_parts.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_role_chip.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// The author's avatar, which forms the card's left column.
class FeedCardAvatar extends StatelessWidget {
  const FeedCardAvatar({
    super.key,
    required this.author,
    required this.onTap,
  });

  final Admin author;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppAvatar(
        radius: 20,
        imageUrl: author.imageUrl,
        fallback: Icon(
          Icons.person,
          size: AppIcon.md,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Who wrote the update: level + name, role tag and time on one line, the
/// handle beneath.
class FeedCardAuthorLine extends StatelessWidget {
  const FeedCardAuthorLine({
    super.key,
    required this.author,
    required this.level,
    required this.createdAt,
    required this.onTap,
  });

  final Admin author;
  final UserLevelModel? level;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final roleLabel = author.displayRoleLabel;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (level != null) ...[
                      FeedLevelBadge(level: level!),
                      const SizedBox(width: AppSpace.xs + 2),
                    ],
                    Flexible(
                      child: Text(
                        author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: AppText.bodySize,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (roleLabel != null) ...[
                const SizedBox(width: AppSpace.sm),
                FeedRoleChip(
                  label: roleLabel,
                  color: FeedRoleChip.colorFor(roleLabel),
                ),
              ],
              const SizedBox(width: AppSpace.sm),
              Text(
                getTimeStamp(createdAt),
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.hair),
          Text(
            _handle(author.username, author.id),
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
    );
  }
}

String _handle(String raw, String id) {
  final trimmed = raw.trim().replaceAll('@', '');
  if (trimmed.isEmpty) {
    return '@${id.substring(0, id.length >= 6 ? 6 : id.length)}';
  }
  return '@$trimmed';
}
