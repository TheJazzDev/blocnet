import 'package:blocnet/services/notifications/notification_target_resolver.dart';

/// A surface that lives in one space's bottom bar. Every space puts its own
/// surface in slot 3 (index 2): Community for users, Hunter Hub for hunters,
/// Moderation for moderators.
enum NotificationSpaceTarget {
  community(space: 'user', label: 'Community'),
  hunterHub(space: 'hunter', label: 'Hunter Hub'),
  moderationHub(space: 'moderation', label: 'Moderation');

  const NotificationSpaceTarget({required this.space, required this.label});

  /// [AuthStore.activeSpace] id that owns this surface.
  final String space;

  /// Human name used in the cross-space sheet.
  final String label;

  /// Bottom-tab index of the surface inside its space.
  int get tab => 2;

  static NotificationSpaceTarget? forSpace(String space) {
    for (final target in values) {
      if (target.space == space) return target;
    }
    return null;
  }

  /// Which other space a notification belongs to, or null when it opens fine
  /// from [activeSpace]. A space the user cannot enter never counts: the
  /// notification then opens where they are.
  static NotificationSpaceTarget? crossSpaceFor({
    required String? type,
    required String? deeplink,
    required String activeSpace,
    required bool hasHunterSpace,
    required bool hasModerationSpace,
  }) {
    final normalizedType = (type ?? '').trim().toLowerCase();
    final path = NotificationTargetResolver.parseDeeplink(deeplink).path;

    if (NotificationTargetResolver.isModerationType(normalizedType)) {
      return hasModerationSpace && activeSpace != 'moderation'
          ? moderationHub
          : null;
    }

    final targetsHunterHub =
        NotificationTargetResolver.isHunterHubType(normalizedType) ||
            path.startsWith('/hunter-hub') ||
            path.startsWith('/manage-updates') ||
            path.startsWith('/manage-projects');
    if (targetsHunterHub) {
      return hasHunterSpace && activeSpace != 'hunter' ? hunterHub : null;
    }

    final targetsCommunity = normalizedType.startsWith('community_') ||
        path.startsWith('/community');
    if (targetsCommunity && activeSpace == 'hunter') return community;

    return null;
  }
}
