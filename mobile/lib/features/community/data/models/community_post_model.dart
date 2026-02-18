import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.authorId,
    required this.topic,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isBookmarked,
    this.admin,
  });

  final String id;
  final String authorId;
  final CommunityTopic topic;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isBookmarked;
  final Admin? admin;

  CommunityPost copyWith({
    CommunityTopic? topic,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isBookmarked,
    Admin? admin,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      admin: admin ?? this.admin,
    );
  }

  factory CommunityPost.fromApi(Map<String, dynamic> json) {
    final rawAdmin = json['admin'] ?? json['author'];
    final admin =
        rawAdmin is Map<String, dynamic> ? Admin.fromApi(rawAdmin) : null;

    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      authorId: (json['authorId'] ?? admin?.id ?? '').toString(),
      topic: CommunityTopic.fromApi(json['topic']?.toString()),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      likesCount: _toInt(json['likesCount']),
      commentsCount: _toInt(json['commentsCount']),
      isLiked: json['isLiked'] == true,
      isBookmarked: json['isBookmarked'] == true,
      admin: admin,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
