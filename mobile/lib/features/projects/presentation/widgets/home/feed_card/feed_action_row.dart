import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The engagement row at the foot of a feed card: like, comment, bookmark,
/// share and **Tip**, spaced evenly.
///
/// Tip is the one that closes Blocnet's loop — it pays a hunter for the
/// obligation they just honoured — so it is the only action drawn as a labelled
/// pill rather than an icon. It used to live only in a profile and in the update
/// detail view, which is far from the moment a member realises the value.
/// [onTipTap] is null when there is nobody to tip, notably on a member's own
/// update, and the pill is then absent rather than disabled.
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
    this.onTipTap,
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
  final VoidCallback? onTipTap;

  @override
  Widget build(BuildContext context) {
    // Evenly spaced across the column, as the feed always laid it out.
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
        if (onTipTap != null) _TipButton(onTap: onTipTap!),
      ],
    );
  }
}

/// Tip, drawn as a small outlined chip so it reads as the one action that
/// moves value rather than one more icon in the row.
class _TipButton extends StatelessWidget {
  const _TipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Padded rather than sized so the label stays centred whatever the
        // text scale; the row's height gives the touch target.
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: AppColors.primary400.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: AppIcon.xs,
              color: AppColors.primary400,
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              'Tip',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
      // Sized to its content with a 44px minimum touch target, not a fixed
      // width. The old fixed 64px was invisible while four buttons shared the
      // row under spaceBetween; adding Tip as a fifth element pushed the row
      // 62px past the screen.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
