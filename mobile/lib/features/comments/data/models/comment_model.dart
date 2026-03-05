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

class CommentModel {
  CommentModel({
    required this.id,
    required this.updateId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.admin,
    this.replyToId,
    this.replyToData,
  });

  final String id;
  final String updateId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final Admin? admin;
  final String? replyToId;
  final ReplyToData? replyToData;

  factory CommentModel.fromApi(Map<String, dynamic> json) {
    final rawAdmin = json['admin'] ?? json['author'];
    final admin = rawAdmin is Map<String, dynamic>
        ? Admin.fromApi(rawAdmin)
        : null;

    final rawReplyTo = json['replyTo'];
    final replyToData = rawReplyTo is Map<String, dynamic>
        ? ReplyToData.fromApi(rawReplyTo)
        : null;

    return CommentModel(
      id: (json['id'] ?? '').toString(),
      updateId: (json['updateId'] ?? json['updateId'] ?? '').toString(),
      authorId: (json['authorId'] ?? admin?.id ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      likesCount: (json['likesCount'] ?? 0) as int,
      admin: admin,
      replyToId: json['replyToId']?.toString(),
      replyToData: replyToData,
    );
  }
}
