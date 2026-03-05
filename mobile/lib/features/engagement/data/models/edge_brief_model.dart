class EdgeBriefProject {
  const EdgeBriefProject({
    required this.projectId,
    required this.projectName,
    required this.count,
    required this.highUrgencyCount,
    required this.avgEdgeScore,
    required this.lastUpdateAt,
  });

  final String projectId;
  final String projectName;
  final int count;
  final int highUrgencyCount;
  final double avgEdgeScore;
  final DateTime? lastUpdateAt;

  factory EdgeBriefProject.fromApi(Map<String, dynamic> json) {
    return EdgeBriefProject(
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      count: int.tryParse((json['count'] ?? '').toString()) ?? 0,
      highUrgencyCount:
          int.tryParse((json['highUrgencyCount'] ?? '').toString()) ?? 0,
      avgEdgeScore:
          double.tryParse((json['avgEdgeScore'] ?? '').toString()) ?? 0,
      lastUpdateAt: DateTime.tryParse((json['lastUpdateAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'count': count,
      'highUrgencyCount': highUrgencyCount,
      'avgEdgeScore': avgEdgeScore,
      'lastUpdateAt': lastUpdateAt?.toIso8601String(),
    };
  }
}

class EdgeBriefDecision {
  const EdgeBriefDecision({
    required this.decisionId,
    required this.edgeScore,
    required this.recommendedAction,
    required this.title,
    required this.projectName,
    required this.urgency,
    required this.createdAt,
  });

  final String decisionId;
  final double edgeScore;
  final String recommendedAction;
  final String title;
  final String projectName;
  final String urgency;
  final DateTime createdAt;

  factory EdgeBriefDecision.fromApi(Map<String, dynamic> json) {
    return EdgeBriefDecision(
      decisionId: (json['decisionId'] ?? '').toString(),
      edgeScore: double.tryParse((json['edgeScore'] ?? '').toString()) ?? 0,
      recommendedAction: (json['recommendedAction'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      urgency: (json['urgency'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'decisionId': decisionId,
      'edgeScore': edgeScore,
      'recommendedAction': recommendedAction,
      'title': title,
      'projectName': projectName,
      'urgency': urgency,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class EdgeBriefResponse {
  const EdgeBriefResponse({
    required this.asOf,
    required this.enabled,
    required this.windowDays,
    required this.totalSignals,
    required this.highUrgencyCount,
    required this.recommendedNowCount,
    required this.watchCount,
    required this.topProjects,
    required this.topDecisions,
    required this.headline,
  });

  final DateTime asOf;
  final bool enabled;
  final int windowDays;
  final int totalSignals;
  final int highUrgencyCount;
  final int recommendedNowCount;
  final int watchCount;
  final List<EdgeBriefProject> topProjects;
  final List<EdgeBriefDecision> topDecisions;
  final String headline;

  bool get hasSignals => totalSignals > 0 || topDecisions.isNotEmpty;

  factory EdgeBriefResponse.fromApi(Map<String, dynamic> json) {
    final topProjects = (json['topProjects'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EdgeBriefProject.fromApi)
        .toList();
    final topDecisions = (json['topDecisions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EdgeBriefDecision.fromApi)
        .toList();

    return EdgeBriefResponse(
      asOf: DateTime.tryParse((json['asOf'] ?? '').toString()) ?? DateTime.now(),
      enabled: json['enabled'] == true,
      windowDays: int.tryParse((json['windowDays'] ?? '').toString()) ?? 7,
      totalSignals: int.tryParse((json['totalSignals'] ?? '').toString()) ?? 0,
      highUrgencyCount:
          int.tryParse((json['highUrgencyCount'] ?? '').toString()) ?? 0,
      recommendedNowCount:
          int.tryParse((json['recommendedNowCount'] ?? '').toString()) ?? 0,
      watchCount: int.tryParse((json['watchCount'] ?? '').toString()) ?? 0,
      topProjects: topProjects,
      topDecisions: topDecisions,
      headline: (json['headline'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asOf': asOf.toIso8601String(),
      'enabled': enabled,
      'windowDays': windowDays,
      'totalSignals': totalSignals,
      'highUrgencyCount': highUrgencyCount,
      'recommendedNowCount': recommendedNowCount,
      'watchCount': watchCount,
      'topProjects': topProjects.map((item) => item.toJson()).toList(),
      'topDecisions': topDecisions.map((item) => item.toJson()).toList(),
      'headline': headline,
    };
  }
}
