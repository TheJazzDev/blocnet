import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/shared/utils/role_presentation.dart';

class Admin {
  final String id;
  final String name;
  final String username;
  final String imageUrl;
  final int followers;
  final double totalTipsReceived;
  final BadgeModel? primaryBadge;
  final UserLevelModel? currentLevel;
  final List<String> roles;

  Admin({
    required this.id,
    required this.name,
    required this.username,
    required this.imageUrl,
    required this.followers,
    this.totalTipsReceived = 0,
    this.primaryBadge,
    this.currentLevel,
    List<String>? roles,
  }) : roles = List.unmodifiable(
          (roles ?? const [])
              .map((role) => role.trim().toLowerCase())
              .where((role) => role.isNotEmpty)
              .toSet()
              .toList(),
        );

  bool hasRole(String role) {
    return roles.contains(role.trim().toLowerCase());
  }

  String? get primaryRoleKey => resolvePrimaryRoleKeyFromRoles(roles);

  String? get displayRoleLabel => resolvePrimaryRoleLabelFromRoles(roles);

  bool get isHunterRole => primaryRoleKey == 'hunter';
  bool get isAdminRole => primaryRoleKey == 'community_admin';

  static List<String> _parseRoles(dynamic rawRoles) {
    if (rawRoles is! List) return const [];
    final roles = <String>{};
    for (final raw in rawRoles) {
      if (raw is String) {
        final value = raw.trim().toLowerCase();
        if (value.isNotEmpty) roles.add(value);
        continue;
      }

      if (raw is Map) {
        final roleValue = raw['role']?.toString().trim().toLowerCase();
        if (roleValue != null && roleValue.isNotEmpty) {
          roles.add(roleValue);
        }
      }
    }
    return roles.toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'imageUrl': imageUrl,
      'followers': followers,
      'totalTipsReceived': totalTipsReceived,
      'roles': roles,
      'primaryBadge': primaryBadge == null
          ? null
          : {
              'id': primaryBadge!.id,
              'slug': primaryBadge!.slug,
              'name': primaryBadge!.name,
              'description': primaryBadge!.description,
              'imageUrl': primaryBadge!.imageUrl,
              'category': primaryBadge!.category.name,
              'rarity': primaryBadge!.rarity.name,
              'pointsRequirement': primaryBadge!.pointsRequirement,
              'isActive': primaryBadge!.isActive,
              'sortOrder': primaryBadge!.sortOrder,
              'createdAt': primaryBadge!.createdAt.toIso8601String(),
            },
    };
  }

  factory Admin.fromApi(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['authorId'] ?? '').toString();
    final fallbackName = 'Blocnet Member';
    final rawName =
        (json['name'] ?? json['displayName'] ?? fallbackName).toString().trim();
    final name = rawName.isEmpty ? fallbackName : rawName;
    final usernameSource = (json['username'] ?? '').toString().trim();
    final normalizedUsername = usernameSource
        .replaceAll('@', '')
        .toLowerCase()
        .replaceAll(' ', '_');
    final username = normalizedUsername.isEmpty
        ? '@${id.isEmpty ? 'member' : id.substring(0, id.length > 6 ? 6 : id.length)}'
        : '@$normalizedUsername';
    final imageUrl = (json['imageUrl'] ?? json['avatarUrl'] ?? '').toString();
    final followersRaw = json['followers'];
    final followers = followersRaw is int
        ? followersRaw
        : int.tryParse(followersRaw?.toString() ?? '') ?? 0;
    final tipsRaw = json['totalTipsReceived'] ?? json['tipsReceived'];
    final totalTipsReceived = tipsRaw is num
        ? tipsRaw.toDouble()
        : double.tryParse(tipsRaw?.toString() ?? '') ?? 0;
    final roles = _parseRoles(json['roles']);

    BadgeModel? primaryBadge;
    final badgeData = json['primaryBadge'];
    if (badgeData != null && badgeData is Map<String, dynamic>) {
      try {
        primaryBadge = BadgeModel.fromApi(badgeData);
      } catch (_) {
        primaryBadge = null;
      }
    }

    UserLevelModel? currentLevel;
    final levelData = json['currentLevel'];
    if (levelData != null && levelData is Map<String, dynamic>) {
      try {
        currentLevel = UserLevelModel.fromApi(levelData);
      } catch (_) {
        currentLevel = null;
      }
    }

    return Admin(
      id: id,
      name: name,
      username: username,
      imageUrl: imageUrl,
      followers: followers,
      totalTipsReceived: totalTipsReceived,
      primaryBadge: primaryBadge,
      currentLevel: currentLevel,
      roles: roles,
    );
  }
}
