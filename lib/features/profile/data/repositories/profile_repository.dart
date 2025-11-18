import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/post_model.dart';
import '../models/activity_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user profile
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return AppUser.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
        null,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Stream user profile
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(
      String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots() as Stream<DocumentSnapshot<Map<String, dynamic>>>;
  }

  // Get followed projects
  Future<List<Project>> getFollowedProjects(List<String> projectIds) async {
    if (projectIds.isEmpty) return [];

    try {
      final querySnapshot = await _firestore
          .collection('projects')
          .where(FieldPath.documentId, whereIn: projectIds)
          .get();

      return querySnapshot.docs
          .map((doc) => Project.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get followed projects: $e');
    }
  }

  // Get saved posts
  Future<List<Post>> getSavedPosts(List<String> postIds) async {
    if (postIds.isEmpty) return [];

    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where(FieldPath.documentId, whereIn: postIds)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get saved posts: $e');
    }
  }

  // Get user activities
  Stream<QuerySnapshot> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (bio != null) updates['bio'] = bio;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
