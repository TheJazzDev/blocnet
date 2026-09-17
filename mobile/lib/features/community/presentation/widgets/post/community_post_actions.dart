import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Like, comment, save and share at the foot of a community post, spaced
/// evenly as on the Home feed.
class CommunityPostActions extends StatelessWidget {
  const CommunityPostActions({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.isCommented,
    required this.commentsCount,
    required this.isSaved,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
  });

  final bool isLiked;
  final int likesCount;
  final bool isCommented;
  final int commentsCount;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final on = AppColors.primary400;
    final off = AppColors.textMuted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommunityActionButton(
          icon:
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isLiked ? on : off,
          count: likesCount,
          label: isLiked ? 'Unlike' : 'Like',
          onTap: onLike,
        ),
        CommunityActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          color: isCommented ? on : off,
          count: commentsCount,
          label: 'Comment',
          onTap: onComment,
        ),
        CommunityActionButton(
          icon:
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isSaved ? on : off,
          label: isSaved ? 'Unsave' : 'Save',
          onTap: onSave,
        ),
        CommunityActionButton(
          icon: Icons.share_outlined,
          color: AppColors.teal400,
          label: 'Share',
          onTap: onShare,
        ),
      ],
    );
  }
}

/// One icon (and optional count) in an action row, with a 44px-wide target.
class CommunityActionButton extends StatelessWidget {
  const CommunityActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.count,
    this.iconSize = AppIcon.md,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final int? count;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              if (count != null) ...[
                const SizedBox(width: AppSpace.xs),
                Text(
                  '${count!}',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
