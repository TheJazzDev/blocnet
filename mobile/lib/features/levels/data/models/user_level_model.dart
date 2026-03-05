class UserLevelModel {
  const UserLevelModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.level,
    required this.requiredBnp,
    required this.requiredComments,
    required this.requiredDaysActive,
    required this.requiredQuests,
    required this.requiredUpdates,
    required this.requiredProjects,
    this.color,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final String iconUrl;
  final int level;
  final String requiredBnp;
  final int requiredComments;
  final int requiredDaysActive;
  final int requiredQuests;
  final int requiredUpdates;
  final int requiredProjects;
  final String? color;
  final bool isActive;
  final int sortOrder;

  factory UserLevelModel.fromApi(Map<String, dynamic> json) {
    return UserLevelModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString() ?? '',
      level: int.tryParse(json['level']?.toString() ?? '') ?? 0,
      requiredBnp: json['requiredBnp']?.toString() ?? '0',
      requiredComments: int.tryParse(json['requiredComments']?.toString() ?? '') ?? 0,
      requiredDaysActive: int.tryParse(json['requiredDaysActive']?.toString() ?? '') ?? 0,
      requiredQuests: int.tryParse(json['requiredQuests']?.toString() ?? '') ?? 0,
      requiredUpdates: int.tryParse(json['requiredUpdates']?.toString() ?? '') ?? 0,
      requiredProjects: int.tryParse(json['requiredProjects']?.toString() ?? '') ?? 0,
      color: json['color']?.toString(),
      isActive: json['isActive'] == true,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
    );
  }
}

class ProgressMetric {
  const ProgressMetric({
    required this.current,
    required this.required,
    required this.percentage,
  });

  final String current;
  final String required;
  final int percentage;

  factory ProgressMetric.fromApi(Map<String, dynamic> json) {
    return ProgressMetric(
      current: json['current']?.toString() ?? '0',
      required: json['required']?.toString() ?? '0',
      percentage: int.tryParse(json['percentage']?.toString() ?? '') ?? 0,
    );
  }
}

class ProgressToNext {
  const ProgressToNext({
    required this.bnp,
    required this.comments,
    required this.daysActive,
    required this.quests,
    required this.updates,
    required this.projects,
  });

  final ProgressMetric bnp;
  final ProgressMetric comments;
  final ProgressMetric daysActive;
  final ProgressMetric quests;
  final ProgressMetric updates;
  final ProgressMetric projects;

  factory ProgressToNext.fromApi(Map<String, dynamic> json) {
    return ProgressToNext(
      bnp: ProgressMetric.fromApi(_asStringKeyMap(json['bnp'])),
      comments: ProgressMetric.fromApi(_asStringKeyMap(json['comments'])),
      daysActive: ProgressMetric.fromApi(_asStringKeyMap(json['daysActive'])),
      quests: ProgressMetric.fromApi(_asStringKeyMap(json['quests'])),
      updates: ProgressMetric.fromApi(_asStringKeyMap(json['updates'])),
      projects: ProgressMetric.fromApi(_asStringKeyMap(json['projects'])),
    );
  }
}

class UserMetrics {
  const UserMetrics({
    required this.totalBnpEarned,
    required this.totalComments,
    required this.totalDaysActive,
    required this.totalQuestsCompleted,
    required this.totalUpdates,
    required this.totalProjects,
  });

  final String totalBnpEarned;
  final int totalComments;
  final int totalDaysActive;
  final int totalQuestsCompleted;
  final int totalUpdates;
  final int totalProjects;

  factory UserMetrics.fromApi(Map<String, dynamic> json) {
    return UserMetrics(
      totalBnpEarned: json['totalBnpEarned']?.toString() ?? '0',
      totalComments: int.tryParse(json['totalComments']?.toString() ?? '') ?? 0,
      totalDaysActive: int.tryParse(json['totalDaysActive']?.toString() ?? '') ?? 0,
      totalQuestsCompleted: int.tryParse(json['totalQuestsCompleted']?.toString() ?? '') ?? 0,
      totalUpdates: int.tryParse(json['totalUpdates']?.toString() ?? '') ?? 0,
      totalProjects: int.tryParse(json['totalProjects']?.toString() ?? '') ?? 0,
    );
  }
}

class UserLevelProgressModel {
  const UserLevelProgressModel({
    required this.currentLevel,
    this.nextLevel,
    required this.achievedAt,
    required this.metrics,
    this.progressToNext,
  });

  final UserLevelModel currentLevel;
  final UserLevelModel? nextLevel;
  final DateTime achievedAt;
  final UserMetrics metrics;
  final ProgressToNext? progressToNext;

  factory UserLevelProgressModel.fromApi(Map<String, dynamic> json) {
    final progressToNextRaw = json['progressToNext'];
    final nextLevelRaw = json['nextLevel'];

    return UserLevelProgressModel(
      currentLevel: UserLevelModel.fromApi(_asStringKeyMap(json['currentLevel'])),
      nextLevel: nextLevelRaw != null
          ? UserLevelModel.fromApi(_asStringKeyMap(nextLevelRaw))
          : null,
      achievedAt: DateTime.tryParse(json['achievedAt']?.toString() ?? '') ?? DateTime.now(),
      metrics: UserMetrics.fromApi(_asStringKeyMap(json['metrics'])),
      progressToNext: progressToNextRaw != null
          ? ProgressToNext.fromApi(_asStringKeyMap(progressToNextRaw))
          : null,
    );
  }
}

Map<String, dynamic> _asStringKeyMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}
