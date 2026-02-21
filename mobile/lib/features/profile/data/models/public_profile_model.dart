class PublicProfileTrust {
  const PublicProfileTrust({
    required this.updatesLast7d,
    required this.updatesLast30d,
    required this.highUrgencyShare30d,
    required this.medianHoursBetweenUpdates,
    required this.lastActiveAt,
  });

  final int updatesLast7d;
  final int updatesLast30d;
  final double highUrgencyShare30d;
  final double? medianHoursBetweenUpdates;
  final DateTime? lastActiveAt;

  factory PublicProfileTrust.fromApi(Map<String, dynamic> json) {
    return PublicProfileTrust(
      updatesLast7d: int.tryParse(json['updatesLast7d']?.toString() ?? '') ?? 0,
      updatesLast30d:
          int.tryParse(json['updatesLast30d']?.toString() ?? '') ?? 0,
      highUrgencyShare30d:
          double.tryParse(json['highUrgencyShare30d']?.toString() ?? '') ?? 0,
      medianHoursBetweenUpdates:
          double.tryParse(json['medianHoursBetweenUpdates']?.toString() ?? ''),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? ''),
    );
  }
}

class PublicProfileStats {
  const PublicProfileStats({
    required this.projectsCreated,
    required this.updatesCreated,
    required this.commentsCreated,
    required this.followersCount,
    required this.followingCount,
  });

  final int projectsCreated;
  final int updatesCreated;
  final int commentsCreated;
  final int followersCount;
  final int followingCount;

  factory PublicProfileStats.fromApi(Map<String, dynamic> json) {
    return PublicProfileStats(
      projectsCreated:
          int.tryParse(json['projectsCreated']?.toString() ?? '') ?? 0,
      updatesCreated:
          int.tryParse(json['updatesCreated']?.toString() ?? '') ?? 0,
      commentsCreated:
          int.tryParse(json['commentsCreated']?.toString() ?? '') ?? 0,
      followersCount:
          int.tryParse(json['followersCount']?.toString() ?? '') ?? 0,
      followingCount:
          int.tryParse(json['followingCount']?.toString() ?? '') ?? 0,
    );
  }
}

class PublicProfileModel {
  const PublicProfileModel({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.roles,
    required this.stats,
    required this.trust,
    required this.createdAt,
  });

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final List<String> roles;
  final PublicProfileStats stats;
  final PublicProfileTrust trust;
  final DateTime createdAt;

  factory PublicProfileModel.fromApi(Map<String, dynamic> json) {
    final statsRaw = json['stats'];
    final trustRaw = json['trust'];
    return PublicProfileModel(
      id: (json['id'] ?? '').toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      stats: statsRaw is Map<String, dynamic>
          ? PublicProfileStats.fromApi(statsRaw)
          : const PublicProfileStats(
              projectsCreated: 0,
              updatesCreated: 0,
              commentsCreated: 0,
              followersCount: 0,
              followingCount: 0,
            ),
      trust: trustRaw is Map<String, dynamic>
          ? PublicProfileTrust.fromApi(trustRaw)
          : const PublicProfileTrust(
              updatesLast7d: 0,
              updatesLast30d: 0,
              highUrgencyShare30d: 0,
              medianHoursBetweenUpdates: null,
              lastActiveAt: null,
            ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
