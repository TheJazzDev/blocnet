import 'package:blocnet/constants/app_routes.dart';

class ParsedNotificationDeeplink {
  const ParsedNotificationDeeplink({
    required this.path,
    this.updateId,
    this.communityPostId,
    this.commentId,
  });

  final String path;
  final String? updateId;
  final String? communityPostId;
  final String? commentId;
}

class NotificationNavigationDecision {
  const NotificationNavigationDecision._({
    this.route,
    this.arguments,
    this.updateId,
    this.space,
    this.spaceTab,
  });

  final String? route;
  final Object? arguments;
  final String? updateId;

  /// Space whose bottom tab [spaceTab] is the target, for surfaces that have
  /// no route of their own (the Moderation hub).
  final String? space;
  final int? spaceTab;

  bool get opensUpdateDetails =>
      updateId != null && updateId!.trim().isNotEmpty;

  bool get opensSpaceTab => space != null && spaceTab != null;

  static NotificationNavigationDecision openUpdate(String updateId) {
    return NotificationNavigationDecision._(updateId: updateId);
  }

  static NotificationNavigationDecision openSpaceTab(String space, int tab) {
    return NotificationNavigationDecision._(space: space, spaceTab: tab);
  }

  static NotificationNavigationDecision push(
    String route, {
    Object? arguments,
  }) {
    return NotificationNavigationDecision._(
      route: route,
      arguments: arguments,
    );
  }
}

class NotificationTargetResolver {
  static String categoryForType(String? type) {
    switch ((type ?? '').trim().toLowerCase()) {
      case 'project_update':
      case 'comment_received':
      case 'project_followed':
      case 'project_unfollowed':
        return 'updates';
      case 'profile_followed':
      case 'profile_unfollowed':
      case 'community_liked':
      case 'community_bookmarked':
        return 'social';
      case 'project_proposal_submitted':
      case 'project_proposal_reviewed':
      case 'admin_application_submitted':
      case 'admin_application_reviewed':
      case 'project_invite_received':
      case 'project_invite_responded':
      case 'project_assignment_changed':
      // Both ask someone to act on a gem's coverage — a hunter to post, a
      // moderator to review — which is Governance's job, not reading.
      case 'project_update_requested':
      case 'project_reported_inactive':
        return 'governance';
      case 'wallet_transfer_sent':
      case 'wallet_transfer_received':
      case 'wallet_deposit_credited':
      case 'wallet_withdrawal_requested':
      case 'wallet_withdrawal_approved':
      case 'wallet_withdrawal_rejected':
      case 'wallet_withdrawal_broadcasted':
      case 'wallet_withdrawal_confirmed':
      case 'wallet_withdrawal_reverted':
      case 'wallet_kyc_reviewed':
      case 'wallet_provision_ready':
      case 'wallet_provision_failed':
        return 'wallet';
      case 'mining_claimed':
      case 'mining_cycle_ready':
      case 'mining_claim_expiring':
      case 'referral_bound':
      case 'referral_admin_bound':
        return 'mining_referrals';
      case 'badge_earned':
      case 'quest_completed':
      case 'quest_verified':
      case 'quest_rejected':
      case 'level_up':
        return 'rewards';
      default:
        return 'system';
    }
  }

  static NotificationNavigationDecision resolve({
    String? type,
    String? updateId,
    String? postId,
    String? deeplink,
    Map<String, dynamic>? payload,
  }) {
    final normalizedType = (type ?? '').trim().toLowerCase();
    final parsed = parseDeeplink(deeplink);
    final finalUpdateId = _firstNonEmpty(
      updateId,
      payload?['updateId']?.toString(),
      parsed.updateId,
    );
    final finalPostId = _firstNonEmpty(
      postId,
      payload?['postId']?.toString(),
      parsed.communityPostId,
    );

    if (normalizedType == 'project_update' ||
        normalizedType == 'comment_received') {
      if (finalUpdateId != null) {
        return NotificationNavigationDecision.openUpdate(finalUpdateId);
      }
    }

    if (normalizedType == 'mention_received') {
      if (finalUpdateId != null) {
        return NotificationNavigationDecision.openUpdate(finalUpdateId);
      }
      if (finalPostId != null) {
        return NotificationNavigationDecision.push(
          AppRoutes.communityDiscussion,
          arguments: finalPostId,
        );
      }
    }

    if (isWalletType(normalizedType)) {
      return NotificationNavigationDecision.push(AppRoutes.walletTransactions);
    }

    if (normalizedType == 'badge_earned') {
      return NotificationNavigationDecision.push(AppRoutes.badges);
    }

    if (normalizedType == 'level_up') {
      return NotificationNavigationDecision.push(AppRoutes.levels);
    }

    if (normalizedType == 'community_liked' ||
        normalizedType == 'community_bookmarked') {
      if (finalPostId != null) {
        return NotificationNavigationDecision.push(
          AppRoutes.communityDiscussion,
          arguments: finalPostId,
        );
      }
      return NotificationNavigationDecision.push(AppRoutes.main);
    }

    if (normalizedType == 'profile_followed' ||
        normalizedType == 'profile_unfollowed') {
      return NotificationNavigationDecision.push(AppRoutes.profile);
    }

    if (normalizedType == 'quest_completed' ||
        normalizedType == 'quest_verified' ||
        normalizedType == 'quest_rejected') {
      return NotificationNavigationDecision.push(AppRoutes.quests);
    }

    if (normalizedType == 'mining_claimed' ||
        normalizedType == 'mining_cycle_ready' ||
        normalizedType == 'mining_claim_expiring') {
      return NotificationNavigationDecision.push(AppRoutes.mining);
    }

    if (normalizedType == 'referral_bound' ||
        normalizedType == 'referral_admin_bound') {
      return NotificationNavigationDecision.push(AppRoutes.referralCode);
    }

    if (isModerationType(normalizedType)) {
      // The Moderation hub has no route; it is slot 3 of Moderation space.
      return NotificationNavigationDecision.openSpaceTab('moderation', 2);
    }

    if (isGovernanceType(normalizedType)) {
      // Members asking for an update: the Hub is where a hunter sees which of
      // their gems need attention.
      if (normalizedType == 'project_update_requested') {
        return NotificationNavigationDecision.push(AppRoutes.hunterHub);
      }
      // The Become Hunter screen shows the application's status.
      if (normalizedType == 'admin_application_reviewed') {
        return NotificationNavigationDecision.push(AppRoutes.becomeHunter);
      }
      // Invites are accepted/declined from the Invites section of Hunter
      // Hub's "Manage My Gems"; assignment changes land there too.
      if (normalizedType == 'project_invite_received' ||
          normalizedType == 'project_invite_responded' ||
          normalizedType == 'project_assignment_changed') {
        return NotificationNavigationDecision.push(AppRoutes.hunterHub);
      }
      return NotificationNavigationDecision.push(AppRoutes.profile);
    }

    final deeplinkPath = parsed.path;
    if (deeplinkPath.contains('profile/badges') ||
        deeplinkPath.endsWith('/badges')) {
      return NotificationNavigationDecision.push(AppRoutes.badges);
    }
    if (deeplinkPath.startsWith('/levels')) {
      return NotificationNavigationDecision.push(AppRoutes.levels);
    }
    if (deeplinkPath.startsWith('/mining')) {
      return NotificationNavigationDecision.push(AppRoutes.mining);
    }
    if (deeplinkPath.startsWith('/quests')) {
      return NotificationNavigationDecision.push(AppRoutes.quests);
    }
    if (deeplinkPath.startsWith('/wallet/transactions')) {
      return NotificationNavigationDecision.push(AppRoutes.walletTransactions);
    }
    if (deeplinkPath.startsWith('/wallet')) {
      return NotificationNavigationDecision.push(AppRoutes.wallet);
    }
    if (deeplinkPath.startsWith('/updates') && finalUpdateId != null) {
      return NotificationNavigationDecision.openUpdate(finalUpdateId);
    }
    if (deeplinkPath.startsWith('/community/posts') && finalPostId != null) {
      return NotificationNavigationDecision.push(
        AppRoutes.communityDiscussion,
        arguments: finalPostId,
      );
    }

    return NotificationNavigationDecision.push(AppRoutes.main);
  }

  static ParsedNotificationDeeplink parseDeeplink(String? rawDeeplink) {
    final raw = rawDeeplink?.trim() ?? '';
    if (raw.isEmpty) {
      return const ParsedNotificationDeeplink(path: '');
    }

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      uri = null;
    }

    if (uri == null) {
      return ParsedNotificationDeeplink(path: raw.toLowerCase());
    }

    final segments = <String>[
      if (uri.scheme.isNotEmpty && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.trim().isNotEmpty),
    ];
    final normalizedSegments = segments.map((segment) => segment.toLowerCase());
    final path =
        normalizedSegments.isEmpty ? '' : '/${normalizedSegments.join('/')}';

    String? updateId =
        _cleanIdentifier(uri.queryParameters['updateId']?.toString());
    String? communityPostId =
        _cleanIdentifier(uri.queryParameters['postId']?.toString());
    String? commentId =
        _cleanIdentifier(uri.queryParameters['commentId']?.toString());

    if (segments.length >= 2 &&
        segments[0].toLowerCase() == 'updates' &&
        segments[1].toLowerCase() != 'comment') {
      updateId = _cleanIdentifier(segments[1]);
    }

    if (segments.length >= 3 &&
        segments[0].toLowerCase() == 'updates' &&
        segments[1].toLowerCase() == 'comment') {
      commentId = _cleanIdentifier(segments[2]) ?? commentId;
    }

    if (segments.length >= 3 &&
        segments[0].toLowerCase() == 'community' &&
        segments[1].toLowerCase() == 'posts' &&
        segments[2].toLowerCase() != 'comment') {
      communityPostId = _cleanIdentifier(segments[2]);
    }

    if (segments.length >= 4 &&
        segments[0].toLowerCase() == 'community' &&
        segments[1].toLowerCase() == 'posts' &&
        segments[2].toLowerCase() == 'comment') {
      commentId = _cleanIdentifier(segments[3]) ?? commentId;
    }

    return ParsedNotificationDeeplink(
      path: path,
      updateId: updateId,
      communityPostId: communityPostId,
      commentId: commentId,
    );
  }

  static bool isWalletType(String type) {
    return type.startsWith('wallet_') ||
        type == 'wallet_transfer' ||
        type == 'wallet_deposit' ||
        type == 'wallet_withdrawal' ||
        type == 'wallet_swap' ||
        type == 'kyc_approved' ||
        type == 'kyc_rejected' ||
        type == 'kyc_pending';
  }

  static bool isGovernanceType(String type) {
    return type == 'project_proposal_submitted' ||
        type == 'project_proposal_reviewed' ||
        type == 'admin_application_submitted' ||
        type == 'admin_application_reviewed' ||
        type == 'project_invite_received' ||
        type == 'project_invite_responded' ||
        type == 'project_assignment_changed' ||
        type == 'project_update_requested' ||
        type == 'project_approved' ||
        type == 'project_rejected' ||
        type == 'project_flagged' ||
        type == 'role_changed';
  }

  static bool isModerationType(String type) {
    return type == 'project_reported_inactive';
  }

  /// Notifications whose target lives in Hunter space. Update and comment
  /// alerts are not among them: update details open from any space.
  static bool isHunterHubType(String type) {
    return type == 'project_update_requested' ||
        type == 'project_proposal_submitted' ||
        type == 'project_proposal_reviewed' ||
        type == 'project_invite_received' ||
        type == 'project_invite_responded' ||
        type == 'project_assignment_changed';
  }

  static String? _firstNonEmpty(
    String? first, [
    String? second,
    String? third,
  ]) {
    return _cleanIdentifier(first) ??
        _cleanIdentifier(second) ??
        _cleanIdentifier(third);
  }

  static String? _cleanIdentifier(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
