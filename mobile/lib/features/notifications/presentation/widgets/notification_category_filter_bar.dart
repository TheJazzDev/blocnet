import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_style.dart';
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

const _categoryKeys = [
  'all',
  'updates',
  'social',
  'governance',
  'wallet',
  'mining_referrals',
  'rewards',
  'system',
];

/// The filters, coloured like the tiles' category pills.
List<NotificationCategoryFilter> get notificationCategoryFilters => [
      for (final key in _categoryKeys)
        NotificationCategoryFilter(
          key: key,
          label: styleForNotificationCategory(key).label,
          color: styleForNotificationCategory(key).color,
        ),
    ];

/// Horizontal row of outlined filter pills.
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
            AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          return _FilterPill(
            option: option,
            selected: option.key == selectedKey,
            onTap: () => onSelect(option.key),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final NotificationCategoryFilter option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = option.color;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AppColors.bgSurface,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Text(
            option.label,
            style: AppText.label(
              selected ? color : AppColors.textMuted,
              weight: selected ? AppText.bold : AppText.semibold,
            ),
          ),
        ),
      ),
    );
  }
}
