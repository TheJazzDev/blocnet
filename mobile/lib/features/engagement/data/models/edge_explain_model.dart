class EdgeExplainUpdate {
  const EdgeExplainUpdate({
    required this.id,
    required this.title,
    required this.urgency,
    required this.projectName,
    required this.projectSlug,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String urgency;
  final String projectName;
  final String projectSlug;
  final DateTime createdAt;

  factory EdgeExplainUpdate.fromApi(Map<String, dynamic> json) {
    return EdgeExplainUpdate(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      urgency: (json['urgency'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      projectSlug: (json['projectSlug'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}

class EdgeExplainComponents {
  const EdgeExplainComponents({
    required this.urgency,
    required this.recency,
    required this.relevance,
    required this.novelty,
    required this.penalties,
  });

  final double urgency;
  final double recency;
  final double relevance;
  final double novelty;
  final double penalties;

  factory EdgeExplainComponents.fromApi(Map<String, dynamic> json) {
    return EdgeExplainComponents(
      urgency: double.tryParse((json['urgency'] ?? '').toString()) ?? 0,
      recency: double.tryParse((json['recency'] ?? '').toString()) ?? 0,
      relevance: double.tryParse((json['relevance'] ?? '').toString()) ?? 0,
      novelty: double.tryParse((json['novelty'] ?? '').toString()) ?? 0,
      penalties: double.tryParse((json['penalties'] ?? '').toString()) ?? 0,
    );
  }
}

class EdgeExplainDetails {
  const EdgeExplainDetails({
    required this.edgeScore,
    required this.recommendedAction,
    required this.reasonCodes,
    required this.explanationPreview,
    required this.components,
    required this.narrative,
  });

  final double edgeScore;
  final String recommendedAction;
  final List<String> reasonCodes;
  final String explanationPreview;
  final EdgeExplainComponents components;
  final String narrative;

  factory EdgeExplainDetails.fromApi(Map<String, dynamic> json) {
    final rawComponents = json['components'];

    return EdgeExplainDetails(
      edgeScore: double.tryParse((json['edgeScore'] ?? '').toString()) ?? 0,
      recommendedAction: (json['recommendedAction'] ?? '').toString(),
      reasonCodes: (json['reasonCodes'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
      explanationPreview: (json['explanationPreview'] ?? '').toString(),
      components: rawComponents is Map<String, dynamic>
          ? EdgeExplainComponents.fromApi(rawComponents)
          : const EdgeExplainComponents(
              urgency: 0,
              recency: 0,
              relevance: 0,
              novelty: 0,
              penalties: 0,
            ),
      narrative: (json['narrative'] ?? '').toString(),
    );
  }
}

class EdgeExplainResponse {
  const EdgeExplainResponse({
    required this.asOf,
    required this.enabled,
    required this.decisionId,
    required this.update,
    required this.explanation,
    required this.message,
  });

  final DateTime asOf;
  final bool enabled;
  final String decisionId;
  final EdgeExplainUpdate? update;
  final EdgeExplainDetails? explanation;
  final String? message;

  bool get hasExplanation => update != null && explanation != null;

  factory EdgeExplainResponse.fromApi(Map<String, dynamic> json) {
    final updateJson = json['update'];
    final explanationJson = json['explanation'];

    return EdgeExplainResponse(
      asOf: DateTime.tryParse((json['asOf'] ?? '').toString()) ?? DateTime.now(),
      enabled: json['enabled'] == true,
      decisionId: (json['decisionId'] ?? '').toString(),
      update: updateJson is Map<String, dynamic>
          ? EdgeExplainUpdate.fromApi(updateJson)
          : null,
      explanation: explanationJson is Map<String, dynamic>
          ? EdgeExplainDetails.fromApi(explanationJson)
          : null,
      message: json['message']?.toString(),
    );
  }
}
