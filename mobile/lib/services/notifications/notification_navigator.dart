import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:provider/provider.dart';

/// Handles navigation when push notifications are tapped
class NotificationNavigator {
  /// Navigate to the appropriate screen based on notification data
  static Future<void> handleNotificationTap(
    BuildContext context,
    RemoteMessage message,
  ) async {
    final data = message.data;
    await handleNotificationPayload(
      context,
      type: data['type']?.toString(),
      updateId: data['updateId']?.toString(),
      postId: data['postId']?.toString(),
      deeplink: data['deeplink']?.toString(),
    );
  }

  static Future<void> handleNotificationPayload(
    BuildContext context, {
    required String? type,
    String? updateId,
    String? postId,
    String? deeplink,
    Map<String, dynamic>? payload,
  }) async {
    final decision = NotificationTargetResolver.resolve(
      type: type,
      updateId: updateId,
      postId: postId,
      deeplink: deeplink,
      payload: payload,
    );

    if (decision.opensUpdateDetails && decision.updateId != null) {
      await _openUpdateDetails(context, decision.updateId!);
      return;
    }

    final route = decision.route;
    if (route == null || route.trim().isEmpty) return;
    _pushNamed(context, route, arguments: decision.arguments);
  }

  static Future<void> _openUpdateDetails(
      BuildContext context, String updateId) async {
    final store = context.read<UpdatesStore>();
    final exists = store.updates.any((u) => u.id == updateId);

    if (!exists) {
      await store.refreshUpdates();
      if (!context.mounted) return;
    }

    final resolved = store.updates.any((u) => u.id == updateId);
    if (!resolved) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update not found. It may have been removed.'),
        ),
      );
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UpdateDetailsDialog(id: updateId);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  static void _pushNamed(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }
}
