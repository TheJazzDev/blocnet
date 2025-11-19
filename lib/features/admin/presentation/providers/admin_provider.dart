import 'package:blocnet/features/projects/data/models/post_type_model.dart';
import 'package:flutter/foundation.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/post_model.dart';
import '../../../projects/data/models/primary_tag_model.dart';
import '../../../projects/data/models/priority_model.dart';
import '../../../projects/data/models/secondary_tag_model.dart';
import '../../data/services/admin_service.dart';
import '../../data/repositories/admin_project_repository.dart';
import '../../data/repositories/admin_post_repository.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  final AdminProjectRepository _projectRepository = AdminProjectRepository();
  final AdminPostRepository _postRepository = AdminPostRepository();

  bool _isAdmin = false;
  List<String> _adminProjectIds = [];
  List<Project> _adminProjects = [];
  bool _isLoading = false;
  String? _error;

  bool get isAdmin => _isAdmin;
  List<String> get adminProjectIds => _adminProjectIds;
  List<Project> get adminProjects => _adminProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize admin status
  Future<void> initialize(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _isAdmin = await _adminService.isUserAdmin(userId);
      if (_isAdmin) {
        _adminProjectIds = await _adminService.getUserAdminProjects(userId);
        _loadAdminProjects();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load admin projects
  void _loadAdminProjects() {
    _projectRepository.getAdminProjects(_adminProjectIds).listen((projects) {
      _adminProjects = projects;
      notifyListeners();
    });
  }

  // Check if user is admin of a specific project
  Future<bool> isAdminOfProject(String userId, String projectId) async {
    return await _adminService.isUserAdminOfProject(userId, projectId);
  }

  // Create new project
  Future<String?> createProject({
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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final projectId = await _projectRepository.createProject(
        adminUserId: adminUserId,
        name: name,
        description: description,
        details: details,
        category: category,
        primaryTag: primaryTag,
        website: website,
        logo: logo,
        imagePath: imagePath,
        apps: apps,
        socials: socials,
      );

      _adminProjectIds.add(projectId);
      _isAdmin = true;

      _isLoading = false;
      notifyListeners();

      return projectId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update project
  Future<bool> updateProject({
    required String projectId,
    required String name,
    required String description,
    required String category,
    required String website,
    String? logo,
    String? imagePath,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _projectRepository.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        category: category,
        website: website,
        logo: logo,
        imagePath: imagePath,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete project
  Future<bool> deleteProject(String projectId, String adminUserId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _projectRepository.deleteProject(projectId, adminUserId);

      _adminProjectIds.remove(projectId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create new post
  Future<String?> createPost({
    required String projectId,
    required String adminId,
    required String title,
    required String content,
    required String description,
    required PostType type,
    required Priority priority,
    required List<SecondaryTag> secondaryTags,
    String? imagePath,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final postId = await _postRepository.createPost(
        projectId: projectId,
        adminId: adminId,
        title: title,
        content: content,
        description: description,
        type: type,
        priority: priority,
        secondaryTags: secondaryTags,
        imagePath: imagePath,
      );

      _isLoading = false;
      notifyListeners();

      return postId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update post
  Future<bool> updatePost({
    required String postId,
    required String projectId,
    required String title,
    required String content,
    required String description,
    required PostType type,
    required Priority priority,
    required List<SecondaryTag> secondaryTags,
    String? image,
    String? imagePath,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _postRepository.updatePost(
        postId: postId,
        projectId: projectId,
        title: title,
        content: content,
        description: description,
        type: type,
        priority: priority,
        secondaryTags: secondaryTags,
        image: image,
        imagePath: imagePath,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete post
  Future<bool> deletePost(String postId, String projectId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _postRepository.deletePost(postId, projectId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get project posts stream
  Stream<List<Post>> getProjectPosts(String projectId) {
    return _postRepository.getProjectPosts(projectId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
