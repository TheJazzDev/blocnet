// import 'dart:convert';
import 'package:blocknet/features/projects/data/models/primary_tag_model.dart';
// import 'package:crypto/crypto.dart';

class Project {
  final String id;
  final String name;
  final String logo;
  final String adminId;
  final String? website;
  final int followerCount;
  final String description;
  final Set<String> postIds;
  final PrimaryTag primaryTag;
  final Map<String, String?> apps;
  final Map<String, String?> socials;

  Project({
    this.website,
    required this.id,
    required this.logo,
    required this.name,
    required this.adminId,
    required this.primaryTag,
    required this.description,
    required this.followerCount,
    this.apps = const {},
    this.socials = const {},
    this.postIds = const {},
  });

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
      adminId: json["adminId"],
      primaryTag: json['primaryTag'],
      description: json['description'],
      followerCount: json['followerCount'] ?? 0,
      website: json['website'],
      apps: {
        'ios': json['iosApp'],
        'android': json['androidApp'],
      },
      socials: {
        'github': json['github'],
        'twitter': json['twitter'],
        'discord': json['discord'],
        'telegram': json['telegram'],
      },
      postIds: (json['postIds'] as List<dynamic>?)
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
      'website': website,
      'socials': socials,
      'adminId': adminId,
      'primaryTag': primaryTag,
      'description': description,
      'postIds': postIds.toList(),
      'followerCount': followerCount,
    };
  }
}
