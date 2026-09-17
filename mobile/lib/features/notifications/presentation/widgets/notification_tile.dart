import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_style.dart';
import 'package:blocnet/features/notifications/presentation/widgets/parts/notif_ui.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

export 'notification_style.dart';

/// One notification as a flat card row: tinted icon square, bold title,
/// muted body, category pill, time. Unread rows sit on the surface with an
/// accent dot; read rows sit on the page ground with a muted title.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    this.now,
  });

  final NotificationModel item;
  final VoidCallback onTap;

  /// Clock override for tests.
  final DateTime? now;

  String _timeLabel() {
    final diff = (now ?? DateTime.now()).difference(item.createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final style = styleForNotificationType(item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Ink(
          decoration: notifCardDecoration(
            ground: isUnread ? AppColors.bgSurface : AppColors.bgBase,
          ),
          padding: AppSpace.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconSquare(
                  icon: style.icon, color: style.color, bordered: true),
              const SizedBox(width: AppSpace.md),
              Expanded(child: _content(style, isUnread)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(NotificationVisualStyle style, bool isUnread) {
    final body = item.body.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                  weight: isUnread ? AppText.bold : AppText.semibold,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(_timeLabel(), style: AppText.caption(AppColors.textFaint)),
            if (isUnread) ...[
              const SizedBox(width: AppSpace.xs),
              Container(
                key: const ValueKey('notification-unread-dot'),
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary500,
                ),
              ),
            ],
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpace.hair),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(AppColors.textMuted, weight: AppText.regular)
                .copyWith(height: 1.4),
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        AppPill.caps(label: style.label, color: style.color),
      ],
    );
  }
}
