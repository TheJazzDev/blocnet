import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_style.dart';
import 'package:blocnet/features/notifications/presentation/widgets/parts/notif_ui.dart';
import 'package:blocnet/services/notifications/notification_space_target.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Preview of a notification that belongs to another space. Resolves to
/// `true` when the user chose to switch spaces and open it.
Future<bool> showCrossSpaceNotificationSheet(
  BuildContext context, {
  required NotificationModel item,
  required NotificationSpaceTarget target,
  required String currentSpaceLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (_) => CrossSpaceNotificationSheet(
      item: item,
      target: target,
      currentSpaceLabel: currentSpaceLabel,
    ),
  );
  return result ?? false;
}

class CrossSpaceNotificationSheet extends StatelessWidget {
  const CrossSpaceNotificationSheet({
    super.key,
    required this.item,
    required this.target,
    required this.currentSpaceLabel,
  });

  final NotificationModel item;
  final NotificationSpaceTarget target;
  final String currentSpaceLabel;

  String get _spaceName => switch (target) {
        NotificationSpaceTarget.community => 'User',
        NotificationSpaceTarget.hunterHub => 'Hunter',
        NotificationSpaceTarget.moderationHub => 'Moderation',
      };

  /// The button takes the accent of the space it opens.
  Color get _targetAccent => switch (target) {
        NotificationSpaceTarget.community => AppColors.userAccent,
        NotificationSpaceTarget.hunterHub => AppColors.hunterAccent,
        NotificationSpaceTarget.moderationHub => AppColors.moderationAccent,
      };

  @override
  Widget build(BuildContext context) {
    final style = styleForNotificationType(item.type);
    final body = item.body.trim();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: AppRadius.full,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'OPENS IN ${target.label.toUpperCase()}',
              style: notifCaps(AppColors.textFaint),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconSquare(
                    icon: style.icon, color: style.color, bordered: true),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppText.body(
                          AppColors.textPrimary,
                          weight: AppText.bold,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.hair),
                        Text(
                          body,
                          style: AppText.label(AppColors.textMuted)
                              .copyWith(height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'You are in $currentSpaceLabel space. '
              'This opens in $_spaceName space.',
              style: AppText.label(AppColors.textFaint),
            ),
            const SizedBox(height: AppSpace.lg),
            SizedBox(
              width: double.infinity,
              child: NotifButton(
                label: 'Switch and open',
                accent: _targetAccent,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              width: double.infinity,
              child: NotifButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
