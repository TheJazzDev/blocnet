import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The engagement row at the foot of a feed card: like, comment and share on
/// the left, bookmark and **Tip** on the right.
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
    return Row(
      children: [
        _ActionButton(
          icon: likeIcon,
          onTap: onLikeTap,
          count: likeCount,
        ),
        const SizedBox(width: AppSpace.xl),
        _ActionButton(
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            size: AppIcon.md,
            color: isCommented ? AppColors.primary400 : AppColors.textMuted,
          ),
          onTap: onCommentTap,
          count: commentCount,
        ),
        const SizedBox(width: AppSpace.xl),
        _ActionButton(
          icon: Icon(
            Icons.share_outlined,
            size: AppIcon.md,
            color: AppColors.textMuted,
          ),
          onTap: onShareTap,
        ),
        const Spacer(),
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
        if (onTipTap != null) ...[
          const SizedBox(width: AppSpace.md),
          _TipButton(onTap: onTipTap!),
        ],
      ],
    );
  }
}

/// Tip, drawn as an outlined pill so it reads as the one action that moves
/// value rather than one more icon in a row of four.
class _TipButton extends StatelessWidget {
  const _TipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 44px minimum touch target, padded rather than sized so the label
        // stays centred whatever the text scale.
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.full,
          border: Border.all(
            color: AppColors.primary400.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: AppIcon.sm,
              color: AppColors.primary400,
            ),
            const SizedBox(width: AppSpace.xs + 2),
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
