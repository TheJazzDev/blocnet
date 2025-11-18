import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  followedProject,
  unfollowedProject,
  savedPost,
  unsavedPost,
  likedPost,
  commentedOnPost,
  createdProject,
  createdPost,
  updatedProject,
  updatedPost,
}

class UserActivity {
  final String id;
  final String userId;
  final ActivityType type;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    Map<String, dynamic>? metadata,
    required this.timestamp,
  }) : metadata = metadata ?? {};

  UserActivity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory UserActivity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return UserActivity(
      id: snapshot.id,
      userId: data['userId'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${data['type']}',
        orElse: () => ActivityType.followedProject,
      ),
      description: data['description'] as String,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'description': description,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Helper getters
  String? get projectId => metadata['projectId'] as String?;
  String? get projectName => metadata['projectName'] as String?;
  String? get postId => metadata['postId'] as String?;
  String? get postTitle => metadata['postTitle'] as String?;
  String? get commentId => metadata['commentId'] as String?;
}
