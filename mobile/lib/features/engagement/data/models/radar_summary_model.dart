class RadarProjectActivity {
  const RadarProjectActivity({
    required this.projectId,
    required this.projectName,
    required this.newCount,
    required this.highCount,
    required this.lastUpdateAt,
  });

  final String projectId;
  final String projectName;
  final int newCount;
  final int highCount;
  final DateTime? lastUpdateAt;

  factory RadarProjectActivity.fromApi(Map<String, dynamic> json) {
    return RadarProjectActivity(
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      newCount: int.tryParse(json['newCount']?.toString() ?? '') ?? 0,
      highCount: int.tryParse(json['highCount']?.toString() ?? '') ?? 0,
      lastUpdateAt: DateTime.tryParse(json['lastUpdateAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'newCount': newCount,
      'highCount': highCount,
      'lastUpdateAt': lastUpdateAt?.toIso8601String(),
    };
  }
}

class RadarSummary {
  const RadarSummary({
    required this.asOf,
    required this.lastSeenAt,
    required this.newUpdatesCount,
    required this.highUrgencyCount,
    required this.activeProjects,
  });

  final DateTime asOf;
  final DateTime? lastSeenAt;
  final int newUpdatesCount;
  final int highUrgencyCount;
  final List<RadarProjectActivity> activeProjects;

  bool get hasUpdates => newUpdatesCount > 0 || highUrgencyCount > 0;

  factory RadarSummary.fromApi(Map<String, dynamic> json) {
    final activeProjects =
        (json['activeProjects'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RadarProjectActivity.fromApi)
            .toList();

    return RadarSummary(
      asOf: DateTime.tryParse(json['asOf']?.toString() ?? '') ?? DateTime.now(),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      newUpdatesCount:
          int.tryParse(json['newUpdatesCount']?.toString() ?? '') ?? 0,
      highUrgencyCount:
          int.tryParse(json['highUrgencyCount']?.toString() ?? '') ?? 0,
      activeProjects: activeProjects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asOf': asOf.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'newUpdatesCount': newUpdatesCount,
      'highUrgencyCount': highUrgencyCount,
      'activeProjects': activeProjects.map((item) => item.toJson()).toList(),
    };
  }
}
