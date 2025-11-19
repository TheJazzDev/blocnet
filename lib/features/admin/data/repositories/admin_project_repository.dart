import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/primary_tag_model.dart';

class AdminProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create new project
  Future<String> createProject({
    required String adminUserId,
    required String name,
    required String description,
    required String details,
    required String category,
    required PrimaryTag primaryTag,
    required String website,
    String? logo,
    String? imagePath,
    Map<String, String?>? apps,
    Map<String, String?>? socials,
  }) async {
    final batch = _firestore.batch();

    // Create project document
    final projectRef = _firestore.collection('projects').doc();
    final now = Timestamp.now().toDate();

    String? logoUrl;
    if (imagePath != null) {
      logoUrl = await _uploadImage(projectRef.id, imagePath);
    }

    final project = Project(
      id: projectRef.id,
      name: name,
      description: description,
      details: details,
      category: category,
      adminId: adminUserId,
      primaryTag: primaryTag,
      logo: logoUrl ?? logo ?? '',
      website: website,
      apps: apps ?? {},
      socials: socials ?? {},
      followerIds: [],
      followersCount: 0,
      postsCount: 0,
      totalLikes: 0,
      createdAt: now,
      lastEditedAt: now,
    );

    batch.set(projectRef, project.toFirestore());

    // Add project to user's adminProjectIds
    final userRef = _firestore.collection('users').doc(adminUserId);
    batch.update(userRef, {
      'adminProjectIds': FieldValue.arrayUnion([projectRef.id]),
      'isAdmin': true,
    });

    await batch.commit();
    return projectRef.id;
  }

  // Update existing project
  Future<void> updateProject({
    required String projectId,
    required String name,
    required String description,
    required String category,
    required String website,
    String? logo,
    String? imagePath,
  }) async {
    String? logoUrl = logo;

    if (imagePath != null) {
      logoUrl = await _uploadImage(projectId, imagePath);
    }

    await _firestore.collection('projects').doc(projectId).update({
      'name': name,
      'description': description,
      'category': category,
      'website': website,
      if (logoUrl != null) 'logo': logoUrl,
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete project
  Future<void> deleteProject(String projectId, String adminUserId) async {
    final batch = _firestore.batch();

    // Delete project document
    final projectRef = _firestore.collection('projects').doc(projectId);
    batch.delete(projectRef);

    // Remove from user's adminProjectIds
    final userRef = _firestore.collection('users').doc(adminUserId);
    batch.update(userRef, {
      'adminProjectIds': FieldValue.arrayRemove([projectId]),
    });

    // Delete all posts for this project
    final postsSnapshot = await _firestore
        .collection('posts')
        .where('projectId', isEqualTo: projectId)
        .get();

    for (var doc in postsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Delete project logo from storage
    try {
      await _storage.ref('projects/$projectId/logo').delete();
    } catch (e) {
      print('Error deleting logo: $e');
    }
  }

  // Get project by ID
  Future<Project?> getProject(String projectId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (!doc.exists) return null;
    return Project.fromFirestore(doc, null);
  }

  // Get all projects that user is admin of
  Stream<List<Project>> getAdminProjects(List<String> projectIds) {
    if (projectIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('projects')
        .where(FieldPath.documentId, whereIn: projectIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc, null))
            .toList());
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(String projectId, String imagePath) async {
    final file = File(imagePath);
    final ref = _storage.ref('projects/$projectId/logo');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
