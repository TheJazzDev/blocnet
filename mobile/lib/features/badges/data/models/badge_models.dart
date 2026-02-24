class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.rarity,
    required this.pointsRequirement,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final String imageUrl;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final int pointsRequirement;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  factory BadgeModel.fromApi(Map<String, dynamic> json) {
    final categoryRaw = json['category']?.toString().trim().toLowerCase() ?? '';
    final rarityRaw = json['rarity']?.toString().trim().toLowerCase() ?? '';
    return BadgeModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: BadgeCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == categoryRaw,
        orElse: () => BadgeCategory.special,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name.toLowerCase() == rarityRaw,
        orElse: () => BadgeRarity.common,
      ),
      pointsRequirement:
          int.tryParse(json['pointsRequirement']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] == true,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

Map<String, dynamic> _asStringKeyMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

enum BadgeCategory {
  engagement,
  mining,
  social,
  trust,
  special,
}

extension BadgeCategoryExtension on BadgeCategory {
  String get displayName {
    switch (this) {
      case BadgeCategory.engagement:
        return 'Engagement';
      case BadgeCategory.mining:
        return 'Mining';
      case BadgeCategory.social:
        return 'Social';
      case BadgeCategory.trust:
        return 'Trust';
      case BadgeCategory.special:
        return 'Special';
    }
  }
}

enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

extension BadgeRarityExtension on BadgeRarity {
  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }

  /// Returns a color for the rarity
  int get color {
    switch (this) {
      case BadgeRarity.common:
        return 0xFF9E9E9E; // Gray
      case BadgeRarity.rare:
        return 0xFF2196F3; // Blue
      case BadgeRarity.epic:
        return 0xFF9C27B0; // Purple
      case BadgeRarity.legendary:
        return 0xFFFFD700; // Gold
    }
  }
}

class UserBadgeModel {
  const UserBadgeModel({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.grantedBy,
    this.metadata,
    required this.badge,
  });

  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final String? grantedBy;
  final Map<String, dynamic>? metadata;
  final BadgeModel badge;

  factory UserBadgeModel.fromApi(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry(key.toString(), value))
        : null;
    final badgeMap = _asStringKeyMap(json['badge']);

    return UserBadgeModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      badgeId: json['badgeId']?.toString() ?? '',
      earnedAt: DateTime.tryParse(json['earnedAt']?.toString() ?? '') ??
          DateTime.now(),
      grantedBy: json['grantedBy']?.toString(),
      metadata: metadata,
      badge: BadgeModel.fromApi(badgeMap),
    );
  }

  bool get isManuallyGranted => grantedBy != null;
}

class UserBadgesResponse {
  const UserBadgesResponse({
    required this.badges,
    required this.totalCount,
    this.primaryBadge,
  });

  final List<UserBadgeModel> badges;
  final int totalCount;
  final BadgeModel? primaryBadge;

  factory UserBadgesResponse.fromApi(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    final badgesList = rawBadges is List ? rawBadges : const [];
    final badges = badgesList
        .whereType<Map>()
        .map((entry) => UserBadgeModel.fromApi(_asStringKeyMap(entry)))
        .toList();
    final primaryMap = _asStringKeyMap(json['primaryBadge']);

    return UserBadgesResponse(
      badges: badges,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      primaryBadge:
          primaryMap.isNotEmpty ? BadgeModel.fromApi(primaryMap) : null,
    );
  }
}
