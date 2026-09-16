import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/services/notifications/notification_space_target.dart';
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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

  @override
  Widget build(BuildContext context) {
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
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(AppRadius.fullValue),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              target.label,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.subtitleSize,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              item.title,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              item.body,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'This alert belongs to ${target.label} in $_spaceName space. '
                'You are in $currentSpaceLabel space.',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                ),
                child: const Text('Switch and open'),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
