import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class CatchUpBanner extends StatelessWidget {
  const CatchUpBanner({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined,
              size: 14, color: AppColors.primary400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Catch-up filter: unseen or high urgency',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 11,
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
                size: 11,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
