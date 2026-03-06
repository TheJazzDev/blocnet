import 'package:blocnet/features/projects/data/models/admin_model.dart';

class ReplyToData {
  ReplyToData({
    required this.id,
    required this.content,
    this.username,
    this.displayName,
  });

  final String id;
  final String content;
  final String? username;
  final String? displayName;

  factory ReplyToData.fromApi(Map<String, dynamic> json) {
    final author = json['author'];
    return ReplyToData(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      username: author is Map ? author['username']?.toString() : null,
      displayName: author is Map ? author['displayName']?.toString() : null,
    );
  }
}

class CommunityPostComment {
  CommunityPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.admin,
    this.replyToId,
    this.replyToData,
  });

  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final bool isLiked;
  final Admin? admin;
  final String? replyToId;
  final ReplyToData? replyToData;

  factory CommunityPostComment.fromApi(Map<String, dynamic> json) {
    final rawAdmin = json['admin'] ?? json['author'];
    final admin =
        rawAdmin is Map<String, dynamic> ? Admin.fromApi(rawAdmin) : null;

    final rawReplyTo = json['replyTo'];
    final replyToData = rawReplyTo is Map<String, dynamic>
        ? ReplyToData.fromApi(rawReplyTo)
        : null;

    return CommunityPostComment(
      id: (json['id'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      authorId: (json['authorId'] ?? admin?.id ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      likesCount: _toInt(json['likesCount']),
      isLiked: json['isLiked'] == true,
      admin: admin,
      replyToId: json['replyToId']?.toString(),
      replyToData: replyToData,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
