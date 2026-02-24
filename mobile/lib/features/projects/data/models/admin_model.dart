import 'package:blocnet/features/badges/data/models/badge_models.dart';

class Admin {
  final String id;
  final String name;
  final String username;
  final String imageUrl;
  final int followers;
  final BadgeModel? primaryBadge;

  Admin({
    required this.id,
    required this.name,
    required this.username,
    required this.imageUrl,
    required this.followers,
    this.primaryBadge,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'imageUrl': imageUrl,
      'followers': followers,
    };
  }

  factory Admin.fromApi(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['authorId'] ?? '').toString();
    final email = json['email']?.toString();
    final fallbackName =
        email != null && email.isNotEmpty ? email.split('@').first : 'Admin';
    final name =
        (json['name'] ?? json['displayName'] ?? fallbackName).toString();
    final usernameSource =
        (json['username'] ?? json['displayName'] ?? fallbackName).toString();
    final username =
        '@${usernameSource.replaceAll('@', '').toLowerCase().replaceAll(' ', '_')}';
    final imageUrl = (json['imageUrl'] ?? json['avatarUrl'] ?? '').toString();
    final followersRaw = json['followers'];
    final followers = followersRaw is int
        ? followersRaw
        : int.tryParse(followersRaw?.toString() ?? '') ?? 0;

    BadgeModel? primaryBadge;
    final badgeData = json['primaryBadge'];
    if (badgeData != null && badgeData is Map<String, dynamic>) {
      try {
        primaryBadge = BadgeModel.fromApi(badgeData);
      } catch (_) {
        primaryBadge = null;
      }
    }

    return Admin(
      id: id,
      name: name,
      username: username,
      imageUrl: imageUrl,
      followers: followers,
      primaryBadge: primaryBadge,
    );
  }
}
