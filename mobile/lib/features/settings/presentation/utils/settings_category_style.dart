import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Icon and colour for a notification category row.
///
/// Mirrors `styleForNotificationCategory` from the notifications restyle,
/// which is not on this branch yet. When it lands, call it here instead.
({IconData icon, Color color}) settingsCategoryStyle(String key) {
  return switch (key) {
    'updates' => (icon: Icons.campaign_outlined, color: AppColors.primary400),
    'social' => (
        icon: Icons.people_alt_outlined,
        color: AppColors.tagPartnership,
      ),
    'governance' => (icon: Icons.gavel_outlined, color: AppColors.warning500),
    'wallet' => (
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.successColor,
      ),
    'mining_referrals' => (
        icon: Icons.bolt_rounded,
        color: AppColors.tagAirdrop,
      ),
    'rewards' => (
        icon: Icons.workspace_premium_outlined,
        color: AppColors.tagInfo,
      ),
    _ => (icon: Icons.settings_suggest_outlined, color: AppColors.tagGeneral),
  };
}
