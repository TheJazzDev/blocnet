import 'admin_model.dart';
import 'priority_model.dart';
import 'project_model.dart';
import 'secondary_tag_model.dart';

class Update {
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
  final int likesCount;
  final int commentsCount;
  final int bookmarksCount;
  final bool isCommented;
  final List<String> secondaryTagIds;
  final List<SecondaryTag> secondaryTags;

  Update({
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
    this.likesCount = 0,
    this.commentsCount = 0,
    this.bookmarksCount = 0,
    this.isCommented = false,
    required List<String> secondaryTagIds,
    required List<SecondaryTag> secondaryTags,
  })  : secondaryTagIds = secondaryTagIds.toSet().toList(),
        secondaryTags = secondaryTags.toSet().toList();

  Update copyWith({Project? project, Admin? admin}) {
    return Update(
      id: id,
      title: title,
      content: content,
      adminId: adminId,
      priority: priority,
      projectId: projectId,
      createdAt: createdAt,
      description: description,
      lastEditedAt: lastEditedAt,
      likesCount: likesCount,
      commentsCount: commentsCount,
      bookmarksCount: bookmarksCount,
      isCommented: isCommented,
      secondaryTagIds: secondaryTagIds,
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
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'bookmarksCount': bookmarksCount,
      'isCommented': isCommented,
      'priority': priority.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastEditedAt': lastEditedAt?.toIso8601String(),
      'secondaryTagIds': secondaryTagIds,
      'secondaryTags': secondaryTags.map((tag) => tag.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Update(id: $id, title: $title, adminId: $adminId, content: $content, projectId: $projectId, description: $description, createdAt: $createdAt, lastEditedAt: $lastEditedAt, priority: $priority, secondaryTags: $secondaryTags)';
  }

  factory Update.fromApi(Map<String, dynamic> json) {
    final content = (json['content'] ?? json['contentMd'] ?? '').toString();
    final createdAtValue = json['createdAt']?.toString();
    final editedAtValue = json['updatedAt']?.toString();
    final rawAdmin = json['admin'] ?? json['author'];
    final admin =
        rawAdmin is Map<String, dynamic> ? Admin.fromApi(rawAdmin) : null;

    final rawProject = json['project'];
    final project =
        rawProject is Map<String, dynamic> ? Project.fromApi(rawProject) : null;

    final projectId = (json['projectId'] ?? project?.id ?? '').toString();
    final adminId =
        (json['adminId'] ?? json['authorId'] ?? admin?.id ?? '').toString();

    final secondaryTagIds = (json['secondaryTagIds'] as List<dynamic>?)
            ?.map((rawId) => rawId.toString())
            .toSet()
            .toList() ??
        [];

    final secondaryTags = (json['secondaryTags'] as List<dynamic>?)
            ?.map((rawTag) {
              if (rawTag is Map<String, dynamic>) {
                return SecondaryTag.fromApi(rawTag);
              }
              return SecondaryTag.fromJson(rawTag.toString());
            })
            .toSet()
            .toList() ??
        [];

    final derivedDescription = content.replaceAll('\n', ' ');

    return Update(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Update').toString(),
      content: content,
      adminId: adminId,
      projectId: projectId,
      description: (json['description'] ??
              (derivedDescription.length > 140
                  ? '${derivedDescription.substring(0, 140)}...'
                  : derivedDescription))
          .toString(),
      likesCount: int.tryParse(json['likesCount']?.toString() ?? '') ?? 0,
      commentsCount:
          int.tryParse(json['commentsCount']?.toString() ?? '') ?? 0,
      bookmarksCount:
          int.tryParse(json['bookmarksCount']?.toString() ?? '') ?? 0,
      isCommented: json['isCommented'] == true,
      priority: Priority.fromJson(
          (json['priority'] ?? json['urgency'] ?? 'low').toString()),
      createdAt: DateTime.tryParse(createdAtValue ?? '') ?? DateTime.now(),
      lastEditedAt: DateTime.tryParse(editedAtValue ?? ''),
      secondaryTagIds: secondaryTagIds,
      secondaryTags: secondaryTags,
      admin: admin,
      project: project,
    );
  }
}
