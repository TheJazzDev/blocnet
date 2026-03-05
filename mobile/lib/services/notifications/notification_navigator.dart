import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:provider/provider.dart';

/// Handles navigation when push notifications are tapped
class NotificationNavigator {
  /// Navigate to the appropriate screen based on notification data
  static Future<void> handleNotificationTap(
    BuildContext context,
    RemoteMessage message,
  ) async {
    final data = message.data;
    final type = (data['type'] as String?)?.trim().toLowerCase() ?? '';
    final updateId = (data['updateId'] as String?)?.trim() ?? '';
    final communityPostId = (data['postId'] as String?)?.trim() ?? '';
    final deeplink = (data['deeplink'] as String?)?.trim() ?? '';

    // Extract IDs from deeplink if not in data
    final parsedDeeplink = _parseDeeplink(deeplink);

    final finalUpdateId = updateId.isNotEmpty
        ? updateId
        : parsedDeeplink['updateId'] as String? ?? '';
    final finalPostId = communityPostId.isNotEmpty
        ? communityPostId
        : parsedDeeplink['postId'] as String? ?? '';

    // Handle different notification types
    if (type == 'project_update' || type == 'comment_received') {
      if (finalUpdateId.isNotEmpty) {
        await _openUpdateDetails(context, finalUpdateId);
        return;
      }
    }

    if (type == 'mention_received') {
      if (finalUpdateId.isNotEmpty) {
        await _openUpdateDetails(context, finalUpdateId);
        return;
      }
      if (finalPostId.isNotEmpty) {
        _pushNamed(context, AppRoutes.communityDiscussion,
            arguments: finalPostId);
        return;
      }
    }

    if (_isWalletType(type)) {
      _pushNamed(context, AppRoutes.walletTransactions);
      return;
    }

    if (type == 'badge_earned') {
      _pushNamed(context, AppRoutes.badges);
      return;
    }

    if (type == 'community_liked' || type == 'community_bookmarked') {
      if (finalPostId.isNotEmpty) {
        _pushNamed(context, AppRoutes.communityDiscussion,
            arguments: finalPostId);
      } else {
        _pushNamed(context, AppRoutes.main);
      }
      return;
    }

    if (type == 'profile_followed' || type == 'profile_unfollowed') {
      _pushNamed(context, AppRoutes.profile);
      return;
    }

    if (_isGovernanceType(type)) {
      if (type == 'project_invite_received' ||
          type == 'project_invite_responded' ||
          type == 'project_assignment_changed') {
        _pushNamed(context, AppRoutes.manageProjects);
      } else {
        _pushNamed(context, AppRoutes.profile);
      }
      return;
    }

    // Fallback to deeplink path parsing
    final deeplinkPath = parsedDeeplink['path'] as String? ?? '';
    if (deeplinkPath.contains('profile/badges') ||
        deeplinkPath.endsWith('/badges')) {
      _pushNamed(context, AppRoutes.badges);
      return;
    }
    if (deeplinkPath.startsWith('/wallet/transactions')) {
      _pushNamed(context, AppRoutes.walletTransactions);
      return;
    }
    if (deeplinkPath.startsWith('/wallet')) {
      _pushNamed(context, AppRoutes.wallet);
      return;
    }
    if (deeplinkPath.startsWith('/updates') && finalUpdateId.isNotEmpty) {
      await _openUpdateDetails(context, finalUpdateId);
      return;
    }
    if (deeplinkPath.startsWith('/community/posts') &&
        finalPostId.isNotEmpty) {
      _pushNamed(context, AppRoutes.communityDiscussion,
          arguments: finalPostId);
      return;
    }

    // Default fallback
    _pushNamed(context, AppRoutes.main);
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

  static Map<String, dynamic> _parseDeeplink(String? rawDeeplink) {
    final raw = rawDeeplink?.trim() ?? '';
    if (raw.isEmpty) {
      return {'path': '', 'updateId': null, 'postId': null};
    }

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return {'path': raw.toLowerCase(), 'updateId': null, 'postId': null};
    }

    final segments = <String>[
      if (uri.scheme.isNotEmpty && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.trim().isNotEmpty),
    ];
    final normalizedSegments = segments.map((segment) => segment.toLowerCase());
    final path =
        normalizedSegments.isEmpty ? '' : '/${normalizedSegments.join('/')}';

    String? updateId = uri.queryParameters['updateId']?.toString().trim();
    String? postId = uri.queryParameters['postId']?.toString().trim();

    // Parse from path segments
    if (segments.length >= 2 &&
        segments[0].toLowerCase() == 'updates' &&
        segments[1].toLowerCase() != 'comment') {
      updateId = segments[1].trim();
    }

    if (segments.length >= 3 &&
        segments[0].toLowerCase() == 'community' &&
        segments[1].toLowerCase() == 'posts' &&
        segments[2].toLowerCase() != 'comment') {
      postId = segments[2].trim();
    }

    return {
      'path': path,
      'updateId': updateId?.isNotEmpty == true ? updateId : null,
      'postId': postId?.isNotEmpty == true ? postId : null,
    };
  }

  static bool _isWalletType(String type) {
    return type == 'wallet_deposit' ||
        type == 'wallet_withdrawal' ||
        type == 'wallet_transfer' ||
        type == 'wallet_swap' ||
        type == 'kyc_approved' ||
        type == 'kyc_rejected' ||
        type == 'kyc_pending';
  }

  static bool _isGovernanceType(String type) {
    return type == 'project_invite_received' ||
        type == 'project_invite_responded' ||
        type == 'project_assignment_changed' ||
        type == 'project_approved' ||
        type == 'project_rejected' ||
        type == 'project_flagged';
  }
}
