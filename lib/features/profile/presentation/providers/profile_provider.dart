import 'package:flutter/foundation.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/post_model.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  AppUser? _userProfile;
  List<Project> _followedProjects = [];
  List<Post> _savedPosts = [];
  List<UserActivity> _activities = [];

  bool _isLoading = false;
  String? _error;

  AppUser? get userProfile => _userProfile;
  List<Project> get followedProjects => _followedProjects;
  List<Post> get savedPosts => _savedPosts;
  List<UserActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserProfile(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userProfile = await _repository.getUserProfile(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFollowedProjects(List<String> projectIds) async {
    try {
      _followedProjects = await _repository.getFollowedProjects(projectIds);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSavedPosts(List<String> postIds) async {
    try {
      _savedPosts = await _repository.getSavedPosts(postIds);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void listenToActivities(String userId) {
    _repository.getUserActivities(userId).listen((snapshot) {
      _activities = snapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc, null))
          .toList();
      notifyListeners();
    });
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateUserProfile(
        userId: userId,
        displayName: displayName,
        photoURL: photoURL,
        bio: bio,
      );

      // Reload profile
      await loadUserProfile(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
