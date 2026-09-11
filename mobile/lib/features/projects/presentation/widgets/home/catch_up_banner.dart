import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class CatchUpBanner extends StatelessWidget {
  const CatchUpBanner({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined,
              size: AppIcon.sm, color: AppColors.primary400),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'Catch-up filter: unseen or high urgency',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.captionSize,
                weight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: AppText.captionSize,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
