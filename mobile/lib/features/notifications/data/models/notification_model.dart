class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.projectId,
    this.updateId,
    this.urgency,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? projectId;
  final String? updateId;
  final String? urgency;
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
      projectId: projectId,
      updateId: updateId,
      urgency: urgency,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  factory NotificationModel.fromApi(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: json['type']?.toString(),
      projectId: json['projectId']?.toString(),
      updateId: json['updateId']?.toString(),
      urgency: json['urgency']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
    );
  }
}
