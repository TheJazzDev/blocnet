import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:flutter/material.dart';

/// The hunter's last update, quoted. Shows the member what they are waiting
/// on, which is more useful than a bare "no updates" line.
class QuietGemLastWords extends StatelessWidget {
  const QuietGemLastWords({
    super.key,
    required this.update,
    required this.daysAgo,
  });

  final Update update;
  final int daysAgo;

  @override
  Widget build(BuildContext context) {
    final title = update.title.trim();
    final body = update.description.trim();
    final quoted = title.isNotEmpty ? title : body;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST UPDATE · $daysAgo DAYS AGO',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '"$quoted"',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class QuietGemButton extends StatelessWidget {
  const QuietGemButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Marks the one action that puts another member's standing in question.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(
            color: danger
                ? AppColors.priorityHigh.withValues(alpha: 0.28)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIcon.sm,
              color: danger ? AppColors.priorityHigh : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color:
                      danger ? AppColors.priorityHigh : AppColors.textSecondary,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
