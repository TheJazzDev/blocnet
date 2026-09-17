import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The line under the discussion header when there is nothing to show yet,
/// or when the comments failed to load.
class CommunityDiscussionEmpty extends StatelessWidget {
  const CommunityDiscussionEmpty({super.key, this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    return Container(
      width: double.infinity,
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              failed ? error! : 'No comments yet. Say something.',
              style: AppTypography.custom(
                color: failed ? AppColors.textSecondary : AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
            ),
          ),
          if (failed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: AppText.labelSize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
