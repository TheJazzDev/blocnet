import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

class FirestoreService {
  // POST SERVICES
  static final postCollections = FirebaseFirestore.instance
      .collection('posts')
      .withConverter(
          fromFirestore: Post.fromFirestore,
          toFirestore: (Post p, _) => p.toJson());

  static Future<QuerySnapshot<Post>> getPostsOnce() {
    try {
      return postCollections.get();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      rethrow;
    }
  }

  static Future<void> addPost(Post post) async {
    try {
      await postCollections.doc(post.id).set(post);
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot<Post>> getPostById(String id) {
    return postCollections.doc(id).get();
  }

  static Future<void> updatePost(String id, Post post) async {
    try {
      await postCollections.doc(id).set(post);
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  // delete a post by ID
  static Future<void> deletePost(String id) async {
    try {
      await postCollections.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

// PROJECT SERVICES
  static final projectsCollection = FirebaseFirestore.instance
      .collection('projects')
      .withConverter(
          fromFirestore: Project.fromFirestore,
          toFirestore: (Project p, _) => p.toJson());

  static Future<QuerySnapshot<Project>> getProjectsOnce() {
    return projectsCollection.get();
  }

  static Future<void> addProject(Project project) async {
    try {
      await projectsCollection.doc(project.id).set(project);
    } catch (e) {
      debugPrint('Error adding project: $e');
      rethrow;
    }
  }

// ADMIN SERVICES
  static final adminsCollection = FirebaseFirestore.instance
      .collection('admins')
      .withConverter(
          fromFirestore: Admin.fromFirestore,
          toFirestore: (Admin a, _) => a.toJson());

  static Future<QuerySnapshot<Admin>> getAdminsOnce() {
    return adminsCollection.get();
  }

  static Future<void> addAdmin(Admin admin) async {
    try {
      await adminsCollection.doc(admin.id).set(admin);
    } catch (e) {
      debugPrint('Error adding admin: $e');
      rethrow;
    }
  }
}
