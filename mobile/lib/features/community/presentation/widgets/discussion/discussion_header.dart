import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// `COMMENTS · 12` above a thread, with "Load older" when there is more.
class DiscussionHeader extends StatelessWidget {
  const DiscussionHeader({
    super.key,
    required this.count,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadOlder,
  });

  final int count;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: AppIcon.sm,
            color: AppColors.primary400,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'COMMENTS · $count',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (count > 0 && hasMore)
            TextButton(
              onPressed: isLoading ? null : onLoadOlder,
              child: Text(
                isLoading ? 'Loading…' : 'Load older',
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
