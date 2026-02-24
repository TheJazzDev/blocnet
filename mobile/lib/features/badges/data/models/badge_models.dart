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
    return BadgeModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BadgeCategory.special,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      pointsRequirement: int.tryParse(json['pointsRequirement']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] == true,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
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
    return UserBadgeModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      earnedAt: DateTime.tryParse(json['earnedAt'] ?? '') ?? DateTime.now(),
      grantedBy: json['grantedBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      badge: BadgeModel.fromApi(json['badge'] as Map<String, dynamic>),
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
    return UserBadgesResponse(
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => UserBadgeModel.fromApi(e as Map<String, dynamic>))
          .toList(),
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      primaryBadge: json['primaryBadge'] != null
          ? BadgeModel.fromApi(json['primaryBadge'] as Map<String, dynamic>)
          : null,
    );
  }
}
