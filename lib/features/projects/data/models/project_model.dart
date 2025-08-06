import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_model.dart';
import 'post_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';

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
  final DateTime createdAt;
  final Set<String> postIds;
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

  Project copyWith({
    List<Post>? posts,
    Admin? admin,
    String? website,
  }) {
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
      website: website ?? this.website,
      followersCount: followersCount,
    );
  }

  // Factory method to create a Project from JSON
  factory Project.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return Project(
      id: data['id'],
      logo: data['logo'],
      name: data['name'],
      details: data['details'],
      adminId: data["adminId"],
      website: data['website'],
      description: data['description'],
      followersCount: data['followersCount'] ?? 0,
      createdAt: DateTime.parse(data['createdAt']),
      primaryTag:  PrimaryTag.fromJson(data['primaryTag']),
      apps: {'ios': data['iosApp'], 'android': data['androidApp']},
      socials: {
        'github': data['github'],
        'twitter': data['twitter'],
        'discord': data['discord'],
        'telegram': data['telegram'],
      },
      postIds: (data['postIds'] as List?)?.whereType<String>().toSet() ?? {},
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
      'description': description,
      'postIds': postIds.toList(),
      'followersCount': followersCount,
      'primaryTag': primaryTag.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
