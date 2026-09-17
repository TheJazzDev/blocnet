class ActivityItem {
  ActivityItem({
    required this.id,
    required this.action,
    required this.resourceType,
    required this.createdAt,
    this.resourceId,
    this.metadata,
  });

  final String id;
  final String action;
  final String resourceType;
  final String? resourceId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  factory ActivityItem.fromApi(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : null;

    return ActivityItem(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      resourceType: (json['resourceType'] ?? '').toString(),
      resourceId: json['resourceId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: metadata,
    );
  }

  /// Short past-tense line for the Activity tab.
  String get label => _labels[action] ?? _toSentenceCase(action);
}

const Map<String, String> _labels = {
  'update.create': 'Posted an update',
  'update.update': 'Edited an update',
  'comment.create': 'Commented on an update',
  'comment.update': 'Edited a comment',
  'comment.delete': 'Deleted a comment',
  'community_post.create': 'Posted in Community',
  'community_post.comment.create': 'Replied in Community',
  'community_post.reaction.add': 'Liked a post',
  'community_post.reaction.remove': 'Unliked a post',
  'community_post.bookmark.add': 'Saved a post',
  'community_post.bookmark.remove': 'Unsaved a post',
  'follow.preferences.update': 'Changed gem alerts',
  'mining.start': 'Started mining',
  'mining.claim': 'Claimed mining',
  'profile.follow': 'Followed a member',
  'profile.unfollow': 'Unfollowed a member',
  'project.create': 'Added a gem',
  'project.update': 'Edited a gem',
  'project.follow': 'Followed a gem',
  'project.unfollow': 'Unfollowed a gem',
  'project_proposal.create': 'Submitted a gem',
  'referral.bind': 'Joined with a referral',
  'tip.sent': 'Sent a tip',
};

String _toSentenceCase(String value) {
  final words = value
      .replaceAll(RegExp(r'[._]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.toLowerCase())
      .toList();
  if (words.isEmpty) return 'Activity';
  final first = words.first;
  words[0] = '${first[0].toUpperCase()}${first.substring(1)}';
  return words.join(' ');
}
