// import 'dart:convert';
import 'admin_model.dart';
import 'post_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
// import 'package:crypto/crypto.dart';

class Project {
  final String id;
  final String name;
  final String logo;
  final Admin? admin;
  final String adminId;
  final String details;
  final String? website;
  final List<Post>? posts;
  final int followersCount;
  final String description;
  final Set<String> postIds;
  final DateTime createdAt;
  final PrimaryTag primaryTag;
  // final DateTime? lastEditedAt;
  final Map<String, String?> apps;
  final Map<String, String?> socials;

  Project({
    this.posts,
    this.admin,
    this.website,
    required this.id,
    required this.logo,
    required this.name,
    required this.details,
    required this.adminId,
    required this.createdAt,
    required this.primaryTag,
    required this.description,
    required this.followersCount,
    this.apps = const {},
    this.socials = const {},
    this.postIds = const {},
  });

  Project copyWith({List<Post>? posts, Admin? admin}) {
    return Project(
      id: id,
      logo: logo,
      name: name,
      apps: apps,
      socials: socials,
      adminId: adminId,
      postIds: postIds,
      details: details,
      createdAt: createdAt,
      primaryTag: primaryTag,
      description: description,
      posts: posts ?? this.posts,
      admin: admin ?? this.admin,
      website: website ?? website,
      followersCount: followersCount,
    );
  }

  // Generate a unique hash for the project
  // String get uniqueHash {
  //   final content = '$name|$website|${socials.values.join("|")}';
  //   return sha256.convert(utf8.encode(content)).toString();
  // }

  // Factory method to create a Project from JSON
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      logo: json['logo'],
      name: json['name'],
      details: json['details'],
      adminId: json["adminId"],
      primaryTag: json['primaryTag'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      followersCount: json['followersCount'] ?? 0,
      website: json['website'],
      apps: {'ios': json['iosApp'], 'android': json['androidApp']},
      socials: {
        'github': json['github'],
        'twitter': json['twitter'],
        'discord': json['discord'],
        'telegram': json['telegram'],
      },
      postIds:
          (json['postIds'] as List<dynamic>?)
              ?.map((postId) => postId.toString())
              .toSet() ??
          {},
    );
  }

  // Method to convert a Project to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logo': logo,
      'apps': apps,
      'name': name,
      'details': details,
      'website': website,
      'socials': socials,
      'adminId': adminId,
      'primaryTag': primaryTag,
      'description': description,
      'postIds': postIds.toList(),
      'followersCount': followersCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
