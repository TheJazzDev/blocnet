import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/models/app_user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is an admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = AppUser.fromFirestore(userDoc, null);
      return user.isAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Check if user is admin of a specific project
  Future<bool> isUserAdminOfProject(String userId, String projectId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = AppUser.fromFirestore(userDoc, null);
      return user.isAdminOfProject(projectId);
    } catch (e) {
      print('Error checking project admin status: $e');
      return false;
    }
  }

  // Get all projects that the user is admin of
  Future<List<String>> getUserAdminProjects(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final user = AppUser.fromFirestore(userDoc, null);
      return user.adminProjectIds;
    } catch (e) {
      print('Error getting admin projects: $e');
      return [];
    }
  }
}
