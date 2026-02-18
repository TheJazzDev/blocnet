import 'package:blocnet/features/projects/data/models/admin_model.dart';

class CommunityPostComment {
  CommunityPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.admin,
  });

  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Admin? admin;

  factory CommunityPostComment.fromApi(Map<String, dynamic> json) {
    final rawAdmin = json['admin'] ?? json['author'];
    final admin =
        rawAdmin is Map<String, dynamic> ? Admin.fromApi(rawAdmin) : null;

    return CommunityPostComment(
      id: (json['id'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      authorId: (json['authorId'] ?? admin?.id ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      admin: admin,
    );
  }
}
