import 'admin_model.dart';
import 'priority_model.dart';
import 'project_model.dart';
import 'secondary_tag_model.dart';

class Post {
  final String title;
  final Admin? admin;
  final String postId;
  final String adminId;
  final String content;
  final Project? project;
  final String projectId;
  final Priority priority;
  final String description;
  final DateTime createdAt;
  final List<SecondaryTag> secondaryTags;

  Post({
    this.admin,
    this.project,
    required this.title,
    required this.postId,
    required this.content,
    required this.adminId,
    required this.priority,
    required this.createdAt,
    required this.projectId,
    required this.description,
    required List<SecondaryTag> secondaryTags,
  }) : secondaryTags = secondaryTags.toSet().toList();

  // Copy with to support updates
  Post copyWith({Project? project, Admin? admin}) {
    return Post(
      title: title,
      postId: postId,
      content: content,
      adminId: adminId,
      priority: priority,
      projectId: projectId,
      createdAt: createdAt,
      description: description,
      admin: admin ?? this.admin,
      secondaryTags: secondaryTags,
      project: project ?? this.project,
    );
  }

  // Factory method to create a Post from JSON data
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'],
      postId: json['postId'],
      adminId: json['adminId'],
      content: json['content'],
      projectId: json['projectId'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      priority: Priority.fromJson(json['priority']),
      secondaryTags: (json['secondaryTags'] as List<dynamic>?)
              ?.map((tag) => SecondaryTag.fromJson(tag))
              .toList() ??
          [],
    );
  }

  // Method to convert a Post to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'postId': postId,
      'adminId': adminId,
      'description': description,
      'priority': priority.toJson(),
      'secondaryTags': secondaryTags.map((tag) => tag.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Override toString method to provide a custom string representation
  @override
  String toString() {
    return 'Post(title: $title, postId: $postId, adminId: $adminId, content: $content, projectId: $projectId, description: $description, createdAt: $createdAt, priority: $priority, secondaryTags: $secondaryTags)';
  }
}
