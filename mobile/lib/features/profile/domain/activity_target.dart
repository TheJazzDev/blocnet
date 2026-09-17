import 'package:blocnet/features/profile/data/models/activity_item_model.dart';

/// What an Activity row opens.
enum ActivityTargetKind { update, gem, communityPost, person, mine, referrals }

class ActivityTarget {
  const ActivityTarget(this.kind, [this.id]);

  final ActivityTargetKind kind;

  /// The update, gem, post or profile id. Null for [ActivityTargetKind.mine]
  /// and [ActivityTargetKind.referrals].
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is ActivityTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'ActivityTarget($kind, $id)';
}

/// Actions that say nothing a member would look for; left out of the list.
const Set<String> hiddenActivityActions = {'radar.ack'};

/// The thing [item] refers to, from the audit row the backend returns
/// (`GET /me/activity`). Null when there is nothing to open, so the row is
/// drawn without a chevron.
ActivityTarget? activityTargetFor(ActivityItem item) {
  String? meta(String key) {
    final value = item.metadata?[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  final resourceId = item.resourceId?.trim();
  final ownId = resourceId == null || resourceId.isEmpty ? null : resourceId;

  ActivityTarget? make(ActivityTargetKind kind, String? id) =>
      id == null ? null : ActivityTarget(kind, id);

  switch (item.action) {
    case 'update.create':
    case 'update.update':
      return make(ActivityTargetKind.update, ownId);
    case 'comment.create':
    case 'comment.update':
    case 'comment.delete':
      return make(ActivityTargetKind.update, meta('updateId'));
    case 'project.create':
    case 'project.update':
      return make(ActivityTargetKind.gem, ownId);
    case 'project.follow':
    case 'project.unfollow':
    case 'follow.preferences.update':
      return make(ActivityTargetKind.gem, meta('projectId'));
    case 'community_post.create':
      return make(ActivityTargetKind.communityPost, ownId);
    case 'community_post.comment.create':
    case 'community_post.reaction.add':
    case 'community_post.reaction.remove':
    case 'community_post.bookmark.add':
    case 'community_post.bookmark.remove':
      return make(ActivityTargetKind.communityPost, meta('postId'));
    case 'profile.follow':
    case 'profile.unfollow':
      return make(ActivityTargetKind.person, meta('followeeId'));
    case 'mining.start':
    case 'mining.claim':
      return const ActivityTarget(ActivityTargetKind.mine);
    case 'referral.bind':
      return const ActivityTarget(ActivityTargetKind.referrals);
    default:
      return null;
  }
}
