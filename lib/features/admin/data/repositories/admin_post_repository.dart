import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../projects/data/models/post_model.dart';
import '../../../../core/config/app_config.dart';

class AdminPostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create new post
  Future<String> createPost({
    required String projectId,
    required String title,
    required String content,
    required PostType type,
    String? imagePath,
  }) async {
    final batch = _firestore.batch();

    // Create post document
    final postRef = _firestore.collection('posts').doc();
    final now = Timestamp.now().toDate();

    String? imageUrl;
    if (imagePath != null) {
      imageUrl = await _uploadImage(postRef.id, imagePath);
    }

    final post = Post(
      id: postRef.id,
      projectId: projectId,
      title: title,
      content: content,
      type: type,
      image: imageUrl,
      likedByUserIds: [],
      likesCount: 0,
      commentsCount: 0,
      viewsCount: 0,
      createdAt: now,
      lastEditedAt: now,
    );

    batch.set(postRef, post.toFirestore());

    // Update project's postsCount
    final projectRef = _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'postsCount': FieldValue.increment(1),
      'lastEditedAt': FieldValue.serverTimestamp(),
    });

    // Create notifications for all followers
    await _createPostNotifications(projectId, postRef.id, title, type);

    await batch.commit();
    return postRef.id;
  }

  // Update existing post
  Future<void> updatePost({
    required String postId,
    required String projectId,
    required String title,
    required String content,
    required PostType type,
    String? image,
    String? imagePath,
  }) async {
    String? imageUrl = image;

    if (imagePath != null) {
      imageUrl = await _uploadImage(postId, imagePath);
    }

    await _firestore.collection('posts').doc(postId).update({
      'title': title,
      'content': content,
      'type': type.toJson(),
      if (imageUrl != null) 'image': imageUrl,
      'lastEditedAt': FieldValue.serverTimestamp(),
    });

    // Create update notifications for followers
    await _createUpdateNotifications(projectId, postId, title);
  }

  // Delete post
  Future<void> deletePost(String postId, String projectId) async {
    final batch = _firestore.batch();

    // Delete post document
    final postRef = _firestore.collection('posts').doc(postId);
    batch.delete(postRef);

    // Update project's postsCount
    final projectRef = _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'postsCount': FieldValue.increment(-1),
    });

    // Delete all comments for this post
    final commentsSnapshot = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Delete post image from storage
    try {
      await _storage.ref('posts/$postId/image').delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Get post by ID
  Future<Post?> getPost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromFirestore(doc, null);
  }

  // Get all posts for a project
  Stream<List<Post>> getProjectPosts(String projectId) {
    return _firestore
        .collection('posts')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .limit(AppConfig.postsPerPage)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc, null)).toList());
  }

  // Create notifications for new post
  Future<void> _createPostNotifications(
    String projectId,
    String postId,
    String postTitle,
    PostType type,
  ) async {
    // Get project details
    final projectDoc =
        await _firestore.collection('projects').doc(projectId).get();
    if (!projectDoc.exists) return;

    final projectData = projectDoc.data()!;
    final followerIds = List<String>.from(projectData['followerIds'] ?? []);

    if (followerIds.isEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.now();

    // Determine notification type
    final notificationType = type == PostType.urgent ? 'urgentPost' : 'newPost';

    for (var userId in followerIds) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userId,
        'type': notificationType,
        'title': projectData['name'],
        'body': postTitle,
        'isRead': false,
        'createdAt': now,
        'data': {
          'projectId': projectId,
          'postId': postId,
        },
      });
    }

    await batch.commit();
  }

  // Create notifications for post update
  Future<void> _createUpdateNotifications(
    String projectId,
    String postId,
    String postTitle,
  ) async {
    // Get project details
    final projectDoc =
        await _firestore.collection('projects').doc(projectId).get();
    if (!projectDoc.exists) return;

    final projectData = projectDoc.data()!;
    final followerIds = List<String>.from(projectData['followerIds'] ?? []);

    if (followerIds.isEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.now();

    for (var userId in followerIds) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userId,
        'type': 'postUpdate',
        'title': projectData['name'],
        'body': 'Updated: $postTitle',
        'isRead': false,
        'createdAt': now,
        'data': {
          'projectId': projectId,
          'postId': postId,
        },
      });
    }

    await batch.commit();
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(String postId, String imagePath) async {
    final file = File(imagePath);
    final ref = _storage.ref('posts/$postId/image');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
