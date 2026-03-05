class SystemAlertModel {
  SystemAlertModel({
    required this.id,
    required this.action,
    required this.source,
    required this.provider,
    required this.status,
    required this.resourceType,
    required this.summary,
    required this.metadata,
    required this.createdAt,
    this.resourceId,
    this.actorId,
    this.actorEmail,
    this.actorDisplayName,
  });

  final String id;
  final String action;
  final String source;
  final String provider;
  final String status;
  final String resourceType;
  final String? resourceId;
  final String summary;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String? actorId;
  final String? actorEmail;
  final String? actorDisplayName;

  factory SystemAlertModel.fromApi(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};
    final rawActor = json['actor'];
    final actor = rawActor is Map<String, dynamic> ? rawActor : null;

    return SystemAlertModel(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      source: (json['source'] ?? 'system').toString(),
      provider: (json['provider'] ?? 'unknown').toString(),
      status: (json['status'] ?? 'info').toString(),
      resourceType: (json['resourceType'] ?? '').toString(),
      resourceId: json['resourceId']?.toString(),
      summary: (json['summary'] ?? '').toString(),
      metadata: metadata,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      actorId: actor?['id']?.toString(),
      actorEmail: actor?['email']?.toString(),
      actorDisplayName: actor?['displayName']?.toString(),
    );
  }
}
