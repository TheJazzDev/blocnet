class EdgeDecisionUpdate {
  const EdgeDecisionUpdate({
    required this.id,
    required this.title,
    required this.urgency,
    required this.createdAt,
    required this.projectId,
    required this.projectName,
    required this.projectSlug,
    required this.secondaryTagIds,
  });

  final String id;
  final String title;
  final String urgency;
  final DateTime createdAt;
  final String projectId;
  final String projectName;
  final String projectSlug;
  final List<String> secondaryTagIds;

  factory EdgeDecisionUpdate.fromApi(Map<String, dynamic> json) {
    return EdgeDecisionUpdate(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      urgency: (json['urgency'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      projectSlug: (json['projectSlug'] ?? '').toString(),
      secondaryTagIds: (json['secondaryTagIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
    );
  }
}

class EdgeDecision {
  const EdgeDecision({
    required this.decisionId,
    required this.edgeScore,
    required this.recommendedAction,
    required this.reasonCodes,
    required this.explanationPreview,
    required this.update,
  });

  final String decisionId;
  final double edgeScore;
  final String recommendedAction;
  final List<String> reasonCodes;
  final String explanationPreview;
  final EdgeDecisionUpdate update;

  factory EdgeDecision.fromApi(Map<String, dynamic> json) {
    final updateJson = json['update'];

    return EdgeDecision(
      decisionId: (json['decisionId'] ?? '').toString(),
      edgeScore: double.tryParse((json['edgeScore'] ?? '').toString()) ?? 0,
      recommendedAction: (json['recommendedAction'] ?? '').toString(),
      reasonCodes: (json['reasonCodes'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
      explanationPreview: (json['explanationPreview'] ?? '').toString(),
      update: updateJson is Map<String, dynamic>
          ? EdgeDecisionUpdate.fromApi(updateJson)
          : EdgeDecisionUpdate(
              id: '',
              title: '',
              urgency: '',
              createdAt: DateTime.now(),
              projectId: '',
              projectName: '',
              projectSlug: '',
              secondaryTagIds: [],
            ),
    );
  }
}

class EdgeFeedResponse {
  const EdgeFeedResponse({
    required this.asOf,
    required this.enabled,
    required this.limit,
    required this.nextCursor,
    required this.items,
  });

  final DateTime asOf;
  final bool enabled;
  final int limit;
  final String? nextCursor;
  final List<EdgeDecision> items;

  factory EdgeFeedResponse.fromApi(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(EdgeDecision.fromApi)
        .toList();

    return EdgeFeedResponse(
      asOf: DateTime.tryParse((json['asOf'] ?? '').toString()) ?? DateTime.now(),
      enabled: json['enabled'] == true,
      limit: int.tryParse((json['limit'] ?? '').toString()) ?? 20,
      nextCursor: json['nextCursor']?.toString(),
      items: items,
    );
  }
}
