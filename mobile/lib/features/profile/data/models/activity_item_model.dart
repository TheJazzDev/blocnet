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

  String get label {
    switch (action) {
      case 'community_post.create':
        return 'Created a community post';
      case 'community_post.comment.create':
        return 'Commented on a community post';
      case 'community_post.reaction.add':
        return 'Liked a community post';
      case 'community_post.reaction.remove':
        return 'Removed a like from a post';
      case 'community_post.bookmark.add':
        return 'Bookmarked a community post';
      case 'community_post.bookmark.remove':
        return 'Removed a bookmark';
      case 'project.follow':
        return 'Added a project to watchlist';
      case 'project.unfollow':
        return 'Removed a project from watchlist';
      case 'profile.follow':
        return 'Followed a hunter profile';
      case 'profile.unfollow':
        return 'Unfollowed a hunter profile';
      case 'tip.sent':
        return 'Sent a tip to a hunter';
      default:
        return _toTitleCase(
          action.replaceAll(RegExp(r'[._]+'), ' ').trim(),
        );
    }
  }
}

String _toTitleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  return trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}
