import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The engagement row at the foot of a feed card: like, comment, share and
/// bookmark, each with its count.
class FeedActionRow extends StatelessWidget {
  const FeedActionRow({
    super.key,
    required this.likeIcon,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onBookmarkTap,
    required this.isBookmarked,
    required this.isCommented,
    required this.likeCount,
    required this.commentCount,
    required this.bookmarkCount,
  });

  final Widget likeIcon;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onBookmarkTap;
  final bool isBookmarked;
  final bool isCommented;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: likeIcon,
          onTap: onLikeTap,
          count: likeCount,
        ),
        _ActionButton(
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            size: AppIcon.md,
            color: isCommented ? AppColors.primary400 : AppColors.textMuted,
          ),
          onTap: onCommentTap,
          count: commentCount,
        ),
        _ActionButton(
          icon: Icon(
            isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: AppIcon.md,
            color: isBookmarked ? AppColors.primary400 : AppColors.textMuted,
          ),
          onTap: onBookmarkTap,
          count: bookmarkCount > 0 ? bookmarkCount : null,
        ),
        _ActionButton(
          icon: Icon(
            Icons.share_outlined,
            size: AppIcon.md,
            color: AppColors.teal400,
          ),
          onTap: onShareTap,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.count,
  });

  final Widget icon;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
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
    );
  }
}
