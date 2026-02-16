import 'admin_model.dart';
import 'priority_model.dart';
import 'project_model.dart';
import 'secondary_tag_model.dart';

class Post {
  final String id;
  final String title;
  final Admin? admin;
  final String adminId;
  final String content;
  final Project? project;
  final String projectId;
  final Priority priority;
  final String description;
  final DateTime createdAt;
  final DateTime? lastEditedAt;
  final List<SecondaryTag> secondaryTags;

  Post({
    this.admin,
    this.project,
    this.lastEditedAt,
    required this.id,
    required this.title,
    required this.content,
    required this.adminId,
    required this.priority,
    required this.createdAt,
    required this.projectId,
    required this.description,
    required List<SecondaryTag> secondaryTags,
  }) : secondaryTags = secondaryTags.toSet().toList();

  Post copyWith({Project? project, Admin? admin}) {
    return Post(
      id: id,
      title: title,
      content: content,
      adminId: adminId,
      priority: priority,
      projectId: projectId,
      createdAt: createdAt,
      description: description,
      lastEditedAt: lastEditedAt,
      admin: admin ?? this.admin,
      secondaryTags: secondaryTags,
      project: project ?? this.project,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'adminId': adminId,
      'content': content,
      'projectId': projectId,
      'description': description,
      'priority': priority.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastEditedAt': lastEditedAt?.toIso8601String(),
      'secondaryTags': secondaryTags.map((tag) => tag.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Post(id: $id, title: $title, adminId: $adminId, content: $content, projectId: $projectId, description: $description, createdAt: $createdAt, lastEditedAt: $lastEditedAt, priority: $priority, secondaryTags: $secondaryTags)';
  }

  factory Post.fromApi(Map<String, dynamic> json) {
    final content = (json['content'] ?? json['contentMd'] ?? '').toString();
    final createdAtValue = json['createdAt']?.toString();
    final editedAtValue = json['updatedAt']?.toString();
    final projectId = (json['projectId'] ?? '').toString();
    final adminId = (json['adminId'] ?? json['authorId'] ?? '').toString();

    final secondaryTags = (json['secondaryTags'] as List<dynamic>?)
            ?.map((rawTag) => SecondaryTag.fromJson(rawTag.toString()))
            .toSet()
            .toList() ??
        [];

    return Post(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Update').toString(),
      content: content,
      adminId: adminId,
      projectId: projectId,
      description: (json['description'] ??
              (content.length > 140
                  ? '${content.substring(0, 140)}...'
                  : content))
          .toString(),
      priority: Priority.fromJson(
          (json['priority'] ?? json['urgency'] ?? 'low').toString()),
      createdAt: DateTime.tryParse(createdAtValue ?? '') ?? DateTime.now(),
      lastEditedAt: DateTime.tryParse(editedAtValue ?? ''),
      secondaryTags: secondaryTags,
    );
  }
}
