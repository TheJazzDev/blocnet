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
    int? followersCount,
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
      followersCount: followersCount ?? this.followersCount,
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

  factory Project.fromApi(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt']?.toString();
    final createdAt = DateTime.tryParse(createdAtValue ?? '') ?? DateTime.now();
    final adminId = (json['adminId'] ?? json['ownerAdminId'] ?? '').toString();

    return Project(
      id: (json['id'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      name: (json['name'] ?? 'Untitled Project').toString(),
      details: (json['details'] ?? json['description'] ?? '').toString(),
      adminId: adminId,
      website: json['website']?.toString(),
      description: (json['description'] ?? '').toString(),
      followersCount: _toInt(json['followersCount']),
      createdAt: createdAt,
      primaryTag: PrimaryTag.fromJson(
        (json['primaryTag'] ?? PrimaryTag.none.displayName).toString(),
      ),
      apps: _toNullableStringMap(json['apps']) ??
          {
            'ios': json['iosApp']?.toString(),
            'android': json['androidApp']?.toString(),
          },
      socials: _toNullableStringMap(json['socials']) ??
          {
            'github': json['github']?.toString(),
            'twitter': json['twitter']?.toString(),
            'discord': json['discord']?.toString(),
            'telegram': json['telegram']?.toString(),
          },
      postIds: (json['postIds'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toSet() ??
          {},
      admin: _readAdmin(json),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, String?>? _toNullableStringMap(dynamic value) {
    if (value is! Map) return null;

    final mapped = <String, String?>{};
    for (final entry in value.entries) {
      mapped[entry.key.toString()] = entry.value?.toString();
    }
    return mapped;
  }

  static Admin? _readAdmin(Map<String, dynamic> json) {
    final rawAdmin = json['admin'];
    if (rawAdmin is Map<String, dynamic>) {
      return Admin.fromApi(rawAdmin);
    }

    final rawOwner = json['ownerAdmin'];
    if (rawOwner is Map<String, dynamic>) {
      return Admin.fromApi(rawOwner);
    }

    return null;
  }
}
