import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class NotificationCategoryFilter {
  const NotificationCategoryFilter({
    required this.key,
    required this.label,
    required this.color,
  });

  final String key;
  final String label;
  final Color color;
}

final List<NotificationCategoryFilter> notificationCategoryFilters = [
  NotificationCategoryFilter(
    key: 'all',
    label: 'All',
    color: AppColors.textSecondary,
  ),
  NotificationCategoryFilter(
    key: 'updates',
    label: 'Updates',
    color: AppColors.teal400,
  ),
  NotificationCategoryFilter(
    key: 'social',
    label: 'Social',
    color: AppColors.primary400,
  ),
  NotificationCategoryFilter(
    key: 'governance',
    label: 'Governance',
    color: AppColors.warning500,
  ),
  NotificationCategoryFilter(
    key: 'wallet',
    label: 'Wallet',
    color: AppColors.successColor,
  ),
  NotificationCategoryFilter(
    key: 'mining_referrals',
    label: 'Mining & Referrals',
    color: AppColors.tagInfo,
  ),
  NotificationCategoryFilter(
    key: 'rewards',
    label: 'Rewards',
    color: AppColors.tagAirdrop,
  ),
  NotificationCategoryFilter(
    key: 'system',
    label: 'System',
    color: AppColors.tagPartnership,
  ),
];

class NotificationCategoryFilterBar extends StatelessWidget {
  const NotificationCategoryFilterBar({
    super.key,
    required this.selectedKey,
    required this.options,
    required this.onSelect,
  });

  final String selectedKey;
  final List<NotificationCategoryFilter> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.sm),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.key == selectedKey;
          return GestureDetector(
            onTap: () => onSelect(option.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color.withValues(alpha: 0.18)
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.fullValue),
                border: Border.all(
                  color: isSelected
                      ? option.color.withValues(alpha: 0.6)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                option.label,
                style: AppTypography.custom(
                  color: isSelected ? option.color : AppColors.textMuted,
                  size: AppText.captionSize,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemCount: options.length,
      ),
    );
  }
}
