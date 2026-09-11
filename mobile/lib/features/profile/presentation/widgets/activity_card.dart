import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.labelSize,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  subtitle,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            time,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
