import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newPost,
  postUpdate,
  commentReply,
  projectUpdate,
  urgentPost,
  newFollower,
  liked,
  mentioned,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    Map<String, dynamic>? data,
    this.isRead = false,
    required this.createdAt,
  }) : data = data ?? {};

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return AppNotification(
      id: snapshot.id,
      userId: data['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.newPost,
      ),
      title: data['title'] as String,
      body: data['body'] as String,
      imageUrl: data['imageUrl'] as String?,
      data: data['data'] as Map<String, dynamic>? ?? {},
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Helper getters for notification data
  String? get projectId => data['projectId'] as String?;
  String? get postId => data['postId'] as String?;
  String? get commentId => data['commentId'] as String?;
}
