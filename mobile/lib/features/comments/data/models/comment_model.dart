import 'package:blocnet/features/projects/data/models/admin_model.dart';

class CommentModel {
  CommentModel({
    required this.id,
    required this.updateId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.admin,
  });

  final String id;
  final String updateId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Admin? admin;

  factory CommentModel.fromApi(Map<String, dynamic> json) {
    final rawAdmin = json['admin'] ?? json['author'];
    final admin = rawAdmin is Map<String, dynamic>
        ? Admin.fromApi(rawAdmin)
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
      admin: admin,
    );
  }
}
