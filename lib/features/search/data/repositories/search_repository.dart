import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/post_model.dart';

class SearchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search projects by name or category
  Future<List<Project>> searchProjects(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();

    // Get all projects (in a real app, this would be paginated)
    final snapshot = await _firestore
        .collection('projects')
        .orderBy('followersCount', descending: true)
        .limit(100)
        .get();

    // Filter in client since Firestore doesn't support full-text search
    final projects = snapshot.docs
        .map((doc) => Project.fromFirestore(doc, null))
        .where((project) =>
            project.name.toLowerCase().contains(queryLower) ||
            project.description.toLowerCase().contains(queryLower) ||
            project.category.toLowerCase().contains(queryLower))
        .toList();

    return projects;
  }

  // Search posts by title or content
  Future<List<Post>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();

    // Get all posts (in a real app, this would be paginated)
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    // Filter in client
    final posts = snapshot.docs
        .map((doc) => Post.fromFirestore(doc, null))
        .where((post) =>
            post.title.toLowerCase().contains(queryLower) ||
            post.content.toLowerCase().contains(queryLower))
        .toList();

    return posts;
  }

  // Search by category
  Future<List<Project>> searchByCategory(String category) async {
    final snapshot = await _firestore
        .collection('projects')
        .where('category', isEqualTo: category)
        .orderBy('followersCount', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => Project.fromFirestore(doc, null))
        .toList();
  }

  // Get trending projects (most followers)
  Future<List<Project>> getTrendingProjects() async {
    final snapshot = await _firestore
        .collection('projects')
        .orderBy('followersCount', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => Project.fromFirestore(doc, null))
        .toList();
  }

  // Get all unique categories
  Future<List<String>> getCategories() async {
    final snapshot = await _firestore.collection('projects').get();

    final categories = snapshot.docs
        .map((doc) => doc.data()['category'] as String)
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }
}
