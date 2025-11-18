import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../profile/data/models/activity_model.dart';

class InteractionsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Follow/Unfollow Project
  Future<void> toggleFollowProject({
    required String userId,
    required String projectId,
    required String projectName,
    required bool isCurrentlyFollowing,
  }) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(userId);
    final projectRef = _firestore.collection('projects').doc(projectId);

    if (isCurrentlyFollowing) {
      // Unfollow
      batch.update(userRef, {
        'followedProjectIds': FieldValue.arrayRemove([projectId]),
      });
      batch.update(projectRef, {
        'followerIds': FieldValue.arrayRemove([userId]),
        'followersCount': FieldValue.increment(-1),
      });

      // Create activity
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'id': activityRef.id,
        'userId': userId,
        'type': ActivityType.unfollowedProject.name,
        'description': 'Unfollowed $projectName',
        'metadata': {
          'projectId': projectId,
          'projectName': projectName,
        },
        'timestamp': Timestamp.now(),
      });
    } else {
      // Follow
      batch.update(userRef, {
        'followedProjectIds': FieldValue.arrayUnion([projectId]),
      });
      batch.update(projectRef, {
        'followerIds': FieldValue.arrayUnion([userId]),
        'followersCount': FieldValue.increment(1),
      });

      // Create activity
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'id': activityRef.id,
        'userId': userId,
        'type': ActivityType.followedProject.name,
        'description': 'Followed $projectName',
        'metadata': {
          'projectId': projectId,
          'projectName': projectName,
        },
        'timestamp': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Save/Unsave Post
  Future<void> toggleSavePost({
    required String userId,
    required String postId,
    required String postTitle,
    required bool isCurrentlySaved,
  }) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(userId);

    if (isCurrentlySaved) {
      // Unsave
      batch.update(userRef, {
        'savedPostIds': FieldValue.arrayRemove([postId]),
      });

      // Create activity
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'id': activityRef.id,
        'userId': userId,
        'type': ActivityType.unsavedPost.name,
        'description': 'Unsaved post: $postTitle',
        'metadata': {
          'postId': postId,
          'postTitle': postTitle,
        },
        'timestamp': Timestamp.now(),
      });
    } else {
      // Save
      batch.update(userRef, {
        'savedPostIds': FieldValue.arrayUnion([postId]),
      });

      // Create activity
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'id': activityRef.id,
        'userId': userId,
        'type': ActivityType.savedPost.name,
        'description': 'Saved post: $postTitle',
        'metadata': {
          'postId': postId,
          'postTitle': postTitle,
        },
        'timestamp': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Like/Unlike Post
  Future<void> toggleLikePost({
    required String userId,
    required String postId,
    required String projectId,
    required String postTitle,
    required bool isCurrentlyLiked,
  }) async {
    final batch = _firestore.batch();

    final postRef = _firestore.collection('posts').doc(postId);
    final projectRef = _firestore.collection('projects').doc(projectId);

    if (isCurrentlyLiked) {
      // Unlike
      batch.update(postRef, {
        'likedByUserIds': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
      batch.update(projectRef, {
        'totalLikes': FieldValue.increment(-1),
      });
    } else {
      // Like
      batch.update(postRef, {
        'likedByUserIds': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
      batch.update(projectRef, {
        'totalLikes': FieldValue.increment(1),
      });

      // Create activity
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'id': activityRef.id,
        'userId': userId,
        'type': ActivityType.likedPost.name,
        'description': 'Liked post: $postTitle',
        'metadata': {
          'postId': postId,
          'postTitle': postTitle,
        },
        'timestamp': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Like/Unlike Comment
  Future<void> toggleLikeComment({
    required String userId,
    required String commentId,
    required bool isCurrentlyLiked,
  }) async {
    final commentRef = _firestore.collection('comments').doc(commentId);

    if (isCurrentlyLiked) {
      await commentRef.update({
        'likedByUserIds': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await commentRef.update({
        'likedByUserIds': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  // Add Comment
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userDisplayName,
    String? userPhotoURL,
    required String content,
  }) async {
    final batch = _firestore.batch();

    // Create comment
    final commentRef = _firestore.collection('comments').doc();
    batch.set(commentRef, {
      'id': commentRef.id,
      'postId': postId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'createdAt': Timestamp.now(),
      'editedAt': null,
      'likedByUserIds': [],
      'likesCount': 0,
    });

    // Update post comments count
    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
    });

    // Create activity
    final activityRef = _firestore.collection('activities').doc();
    batch.set(activityRef, {
      'id': activityRef.id,
      'userId': userId,
      'type': ActivityType.commentedOnPost.name,
      'description': 'Commented on a post',
      'metadata': {
        'postId': postId,
        'commentId': commentRef.id,
      },
      'timestamp': Timestamp.now(),
    });

    await batch.commit();
    return commentRef.id;
  }

  // Edit Comment
  Future<void> editComment({
    required String commentId,
    required String content,
  }) async {
    await _firestore.collection('comments').doc(commentId).update({
      'content': content,
      'editedAt': Timestamp.now(),
    });
  }

  // Delete Comment
  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    final batch = _firestore.batch();

    // Delete comment
    final commentRef = _firestore.collection('comments').doc(commentId);
    batch.delete(commentRef);

    // Update post comments count
    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Get Comments for Post
  Stream<QuerySnapshot> getCommentsForPost(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Increment Post Views
  Future<void> incrementPostViews(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'viewsCount': FieldValue.increment(1),
    });
  }
}
