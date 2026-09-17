import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/presentation/widgets/cross_space_notification_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/notification_navigator.dart';
import 'package:blocnet/services/notifications/notification_space_target.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens what [item] points at. A target in another space asks first, via
/// the cross-space sheet, then switches space and opens it.
Future<void> openNotificationTarget(
  BuildContext context,
  NotificationModel item,
) async {
  final auth = context.read<AuthStore>();
  final target = NotificationSpaceTarget.crossSpaceFor(
    type: item.type,
    deeplink: item.deeplink,
    activeSpace: auth.activeSpace,
    hasHunterSpace: auth.hasHunterSpace,
    hasModerationSpace: auth.hasModerationSpace,
  );
  final postId = item.payload?['postId']?.toString();

  if (target != null) {
    final switchSpace = await showCrossSpaceNotificationSheet(
      context,
      item: item,
      target: target,
      currentSpaceLabel: SpaceMeta.currentFor(auth).label,
    );
    if (!switchSpace || !context.mounted) return;
    await NotificationNavigator.switchSpaceAndOpen(
      context,
      target: target,
      type: item.type,
      updateId: item.updateId,
      postId: postId,
      deeplink: item.deeplink,
      payload: item.payload,
    );
    return;
  }

  await NotificationNavigator.handleNotificationPayload(
    context,
    type: item.type,
    updateId: item.updateId,
    postId: postId,
    deeplink: item.deeplink,
    payload: item.payload,
  );
}
