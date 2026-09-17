import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:flutter/material.dart';

/// Icon, colour and label for one notification category.
class NotificationVisualStyle {
  const NotificationVisualStyle({
    required this.icon,
    required this.color,
    required this.label,
    required this.categoryKey,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String categoryKey;
}

String categoryForNotificationType(String? type) {
  return NotificationTargetResolver.categoryForType(type);
}

NotificationVisualStyle styleForNotificationType(String? type) {
  return styleForNotificationCategory(categoryForNotificationType(type));
}

/// One colour per category, all from [AppColors], none repeated.
NotificationVisualStyle styleForNotificationCategory(String categoryKey) {
  final (icon, color, label) = switch (categoryKey) {
    'all' => (Icons.notifications_outlined, AppColors.textSecondary, 'All'),
    'updates' => (Icons.campaign_outlined, AppColors.primary400, 'Updates'),
    'social' => (
        Icons.people_alt_outlined,
        AppColors.tagPartnership,
        'Social',
      ),
    'governance' => (
        Icons.gavel_outlined,
        AppColors.warning500,
        'Governance',
      ),
    'wallet' => (
        Icons.account_balance_wallet_outlined,
        AppColors.successColor,
        'Wallet',
      ),
    'mining_referrals' => (
        Icons.bolt_rounded,
        AppColors.tagAirdrop,
        'Mining & Referrals',
      ),
    'rewards' => (
        Icons.workspace_premium_outlined,
        AppColors.tagInfo,
        'Rewards',
      ),
    _ => (Icons.settings_suggest_outlined, AppColors.tagGeneral, 'System'),
  };
  return NotificationVisualStyle(
    icon: icon,
    color: color,
    label: label,
    categoryKey: categoryKey,
  );
}
