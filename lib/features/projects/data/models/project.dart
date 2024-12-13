import 'package:blocknet/features/projects/data/models/post.dart';

class Project {
  final String id;
  final String name;
  final String logo;
  final String description;
  final String primaryTag;
  final int followerCount;
  final String adminUsername;
  final List<Post> posts;

  Project({
    required this.id,
    required this.logo,
    required this.name,
    required this.description,
    required this.primaryTag,
    required this.followerCount,
    required this.adminUsername,
    this.posts = const [],
  });

  // Factory method to create a Project from Firebase data (JSON)
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      logo: json['logo'],
      name: json['name'],
      description: json['description'],
      primaryTag: json['primaryTag'],
      followerCount: json['followerCount'] ?? 0,
      adminUsername: json['adminUsername'],
      posts: (json['posts'] as List<dynamic>?)
              ?.map((post) => Post.fromJson(post))
              .toList() ??
          [],
    );
  }

  // Method to convert a Project to JSON for Firebase or other uses
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      "logo": logo,
      'name': name,
      'description': description,
      'primaryTag': primaryTag,
      'followerCount': followerCount,
      'adminUsername': adminUsername,
      'posts': posts.map((post) => post.toJson()).toList(),
    };
  }
}
