import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Factory method to create a Post from Firestore DocumentSnapshot
  factory Post.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return Post(
      id: snapshot.id,
      title: data['title'],
      adminId: data['adminId'],
      content: data['content'],
      projectId: data['projectId'],
      description: data['description'],
      createdAt: DateTime.parse(data['createdAt']),
      priority: Priority.fromJson(data['priority']),
      lastEditedAt: data['lastEditedAt'] != null
          ? DateTime.parse(data['lastEditedAt'])
          : null,
      secondaryTags: (data['secondaryTags'] as List<dynamic>?)
              ?.map((tag) => SecondaryTag.fromJson(tag))
              .toList() ??
          [],
    );
  }

  /// Convert a Post to a JSON Map (for Firestore)
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
}
