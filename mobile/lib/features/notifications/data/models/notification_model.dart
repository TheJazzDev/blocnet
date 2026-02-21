class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.actorUserId,
    this.projectId,
    this.updateId,
    this.urgency,
    this.payload,
    this.deeplink,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? actorUserId;
  final String? projectId;
  final String? updateId;
  final String? urgency;
  final Map<String, dynamic>? payload;
  final String? deeplink;
  final DateTime? readAt;

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      actorUserId: actorUserId,
      projectId: projectId,
      updateId: updateId,
      urgency: urgency,
      payload: payload,
      deeplink: deeplink,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  factory NotificationModel.fromApi(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    Map<String, dynamic>? payload;
    if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    }

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: json['type']?.toString(),
      actorUserId: json['actorUserId']?.toString(),
      projectId: json['projectId']?.toString(),
      updateId: json['updateId']?.toString(),
      urgency: json['urgency']?.toString(),
      payload: payload,
      deeplink: json['deeplink']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
    );
  }
}
