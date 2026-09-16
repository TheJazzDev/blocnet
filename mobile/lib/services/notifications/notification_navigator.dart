import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/pages/main_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/notification_space_target.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles navigation when push notifications are tapped
class NotificationNavigator {
  /// Read by `MainScreen` after a space switch to pick the landing tab.
  static const String _pendingTabKey = 'navigate_to_tab_after_switch';

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

    if (decision.opensSpaceTab) {
      final target = NotificationSpaceTarget.forSpace(decision.space!);
      if (target != null) await _openSpaceTab(context, target);
      return;
    }

    final route = decision.route;
    if (route == null || route.trim().isEmpty) return;
    _pushNamed(context, route, arguments: decision.arguments);
  }

  /// Leaves the current space for [target]'s space, lands on its tab, then
  /// opens whatever the notification points at inside it.
  static Future<void> switchSpaceAndOpen(
    BuildContext context, {
    required NotificationSpaceTarget target,
    required String? type,
    String? updateId,
    String? postId,
    String? deeplink,
    Map<String, dynamic>? payload,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await _openSpaceTab(context, target);

    final decision = NotificationTargetResolver.resolve(
      type: type,
      updateId: updateId,
      postId: postId,
      deeplink: deeplink,
      payload: payload,
    );
    // The page we navigate from was popped; the root navigator outlives it.
    final rootContext = navigator.context;
    if (!rootContext.mounted) return;

    if (decision.opensUpdateDetails) {
      await _openUpdateDetails(rootContext, decision.updateId!);
      return;
    }
    final route = decision.route;
    // The space tab already is the Hub, and `main` is where we are.
    if (decision.opensSpaceTab ||
        route == null ||
        route == AppRoutes.hunterHub ||
        route == AppRoutes.main) {
      return;
    }
    _pushNamed(rootContext, route, arguments: decision.arguments);
  }

  /// Back to the shell, showing [target]'s tab in [target]'s space.
  static Future<void> _openSpaceTab(
    BuildContext context,
    NotificationSpaceTarget target,
  ) async {
    final auth = context.read<AuthStore>();
    final navigator = Navigator.of(context, rootNavigator: true);

    if (auth.activeSpace == target.space) {
      // Same space: the shell only picks a tab when it is built or when the
      // space changes, so replace the stack with a shell on that tab.
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.main),
          builder: (_) => MainScreen(initialIndex: target.tab),
        ),
        (_) => false,
      );
      return;
    }

    final canEnter = switch (target.space) {
      'hunter' => auth.hasHunterSpace,
      'moderation' => auth.hasModerationSpace,
      _ => true,
    };
    if (!canEnter || auth.isSwitchingSpace) return;

    navigator.popUntil((route) => route.isFirst);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pendingTabKey, target.tab);
    await auth.switchSpaceWithTransition(target.space);
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
