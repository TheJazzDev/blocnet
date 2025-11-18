import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userDisplayName;
  final String? userPhotoURL;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final List<String> likedByUserIds;
  final int likesCount;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoURL,
    required this.content,
    required this.createdAt,
    this.editedAt,
    List<String>? likedByUserIds,
    int? likesCount,
  })  : likedByUserIds = likedByUserIds ?? [],
        likesCount = likesCount ?? 0;

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userDisplayName,
    String? userPhotoURL,
    String? content,
    DateTime? createdAt,
    DateTime? editedAt,
    List<String>? likedByUserIds,
    int? likesCount,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  factory Comment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return Comment(
      id: snapshot.id,
      postId: data['postId'] as String,
      userId: data['userId'] as String,
      userDisplayName: data['userDisplayName'] as String,
      userPhotoURL: data['userPhotoURL'] as String?,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      likedByUserIds:
          (data['likedByUserIds'] as List?)?.cast<String>() ?? [],
      likesCount: data['likesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'likedByUserIds': likedByUserIds,
      'likesCount': likesCount,
    };
  }

  bool isLikedByUser(String userId) {
    return likedByUserIds.contains(userId);
  }
}
