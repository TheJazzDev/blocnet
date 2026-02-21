class DigestMissedUpdate {
  const DigestMissedUpdate({
    required this.updateId,
    required this.title,
    required this.projectId,
    required this.projectName,
    required this.urgency,
    required this.createdAt,
  });

  final String updateId;
  final String title;
  final String projectId;
  final String projectName;
  final String urgency;
  final DateTime createdAt;

  factory DigestMissedUpdate.fromApi(Map<String, dynamic> json) {
    return DigestMissedUpdate(
      updateId: (json['updateId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      urgency: (json['urgency'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class DigestActiveProject {
  const DigestActiveProject({
    required this.projectId,
    required this.projectName,
    required this.newCount,
    required this.highCount,
    required this.lastUpdateAt,
  });

  final String projectId;
  final String projectName;
  final int newCount;
  final int highCount;
  final DateTime? lastUpdateAt;

  factory DigestActiveProject.fromApi(Map<String, dynamic> json) {
    return DigestActiveProject(
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      newCount: int.tryParse(json['newCount']?.toString() ?? '') ?? 0,
      highCount: int.tryParse(json['highCount']?.toString() ?? '') ?? 0,
      lastUpdateAt: DateTime.tryParse(json['lastUpdateAt']?.toString() ?? ''),
    );
  }
}

class DigestCommunityPost {
  const DigestCommunityPost({
    required this.id,
    required this.topic,
    required this.contentPreview,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  final String id;
  final String topic;
  final String contentPreview;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  factory DigestCommunityPost.fromApi(Map<String, dynamic> json) {
    return DigestCommunityPost(
      id: (json['id'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      contentPreview: (json['contentPreview'] ?? '').toString(),
      likesCount: int.tryParse(json['likesCount']?.toString() ?? '') ?? 0,
      commentsCount: int.tryParse(json['commentsCount']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class DigestSummary {
  const DigestSummary({
    required this.windowDays,
    required this.missedHighUrgency,
    required this.activeProjects,
    required this.topCommunityPosts,
  });

  final int windowDays;
  final List<DigestMissedUpdate> missedHighUrgency;
  final List<DigestActiveProject> activeProjects;
  final List<DigestCommunityPost> topCommunityPosts;

  bool get hasAnyInsight =>
      missedHighUrgency.isNotEmpty ||
      activeProjects.isNotEmpty ||
      topCommunityPosts.isNotEmpty;

  factory DigestSummary.fromApi(Map<String, dynamic> json) {
    final missed = (json['missedHighUrgency'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DigestMissedUpdate.fromApi)
        .toList();
    final active = (json['activeProjects'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DigestActiveProject.fromApi)
        .toList();
    final community = (json['topCommunityPosts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DigestCommunityPost.fromApi)
        .toList();

    return DigestSummary(
      windowDays: int.tryParse(json['windowDays']?.toString() ?? '') ?? 7,
      missedHighUrgency: missed,
      activeProjects: active,
      topCommunityPosts: community,
    );
  }
}
