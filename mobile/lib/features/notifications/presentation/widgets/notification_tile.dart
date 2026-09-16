import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:flutter/material.dart';

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
  final categoryKey = categoryForNotificationType(type);
  switch (categoryKey) {
    case 'updates':
      return NotificationVisualStyle(
        icon: Icons.campaign_outlined,
        color: AppColors.teal400,
        label: 'Updates',
        categoryKey: categoryKey,
      );
    case 'social':
      return NotificationVisualStyle(
        icon: Icons.people_alt_outlined,
        color: AppColors.primary400,
        label: 'Social',
        categoryKey: categoryKey,
      );
    case 'governance':
      return NotificationVisualStyle(
        icon: Icons.gavel_outlined,
        color: AppColors.warning500,
        label: 'Governance',
        categoryKey: categoryKey,
      );
    case 'wallet':
      return NotificationVisualStyle(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.successColor,
        label: 'Wallet',
        categoryKey: categoryKey,
      );
    case 'mining_referrals':
      return NotificationVisualStyle(
        icon: Icons.bolt_rounded,
        color: AppColors.tagInfo,
        label: 'Mining & Referrals',
        categoryKey: categoryKey,
      );
    case 'rewards':
      return NotificationVisualStyle(
        icon: Icons.workspace_premium_outlined,
        color: AppColors.tagAirdrop,
        label: 'Rewards',
        categoryKey: categoryKey,
      );
    default:
      return NotificationVisualStyle(
        icon: Icons.settings_suggest_outlined,
        color: AppColors.tagPartnership,
        label: 'System',
        categoryKey: categoryKey,
      );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.mode,
    required this.onTap,
  });

  final NotificationModel item;
  final FeedViewMode mode;
  final VoidCallback onTap;

  String _timeLabel() {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final style = styleForNotificationType(item.type);

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary500.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isUnread
              ? style.color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(mode == FeedViewMode.card ? 10 : 8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: mode == FeedViewMode.card ? 10 : 12,
            horizontal: mode == FeedViewMode.card ? 10 : 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: AppSpace.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnread ? style.color : Colors.transparent,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                  border: Border.all(
                    color: style.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  style.icon,
                  size: AppIcon.sm,
                  color: style.color,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.custom(
                        color: isUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      item.body,
                      style: AppTypography.custom(
                        color: isUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        size: AppText.bodySize,
                        weight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm, vertical: AppSpace.hair),
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.fullValue),
                      ),
                      child: Text(
                        style.label,
                        style: AppTypography.custom(
                          color: style.color,
                          size: AppText.captionSize,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                _timeLabel(),
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationRowWrapper extends StatelessWidget {
  const NotificationRowWrapper({
    super.key,
    required this.mode,
    required this.showDivider,
    required this.child,
  });

  final FeedViewMode mode;
  final bool showDivider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (mode == FeedViewMode.card) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
        ),
        child: child,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: showDivider ? 6 : 2),
      child: child,
    );
  }
}
