import 'package:flutter/foundation.dart';
import '../../data/repositories/interactions_repository.dart';

class InteractionsProvider with ChangeNotifier {
  final InteractionsRepository _repository = InteractionsRepository();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> toggleFollowProject({
    required String userId,
    required String projectId,
    required String projectName,
    required bool isCurrentlyFollowing,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.toggleFollowProject(
        userId: userId,
        projectId: projectId,
        projectName: projectName,
        isCurrentlyFollowing: isCurrentlyFollowing,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleSavePost({
    required String userId,
    required String postId,
    required String postTitle,
    required bool isCurrentlySaved,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.toggleSavePost(
        userId: userId,
        postId: postId,
        postTitle: postTitle,
        isCurrentlySaved: isCurrentlySaved,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleLikePost({
    required String userId,
    required String postId,
    required String projectId,
    required String postTitle,
    required bool isCurrentlyLiked,
  }) async {
    try {
      await _repository.toggleLikePost(
        userId: userId,
        postId: postId,
        projectId: projectId,
        postTitle: postTitle,
        isCurrentlyLiked: isCurrentlyLiked,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleLikeComment({
    required String userId,
    required String commentId,
    required bool isCurrentlyLiked,
  }) async {
    try {
      await _repository.toggleLikeComment(
        userId: userId,
        commentId: commentId,
        isCurrentlyLiked: isCurrentlyLiked,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> addComment({
    required String postId,
    required String userId,
    required String userDisplayName,
    String? userPhotoURL,
    required String content,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final commentId = await _repository.addComment(
        postId: postId,
        userId: userId,
        userDisplayName: userDisplayName,
        userPhotoURL: userPhotoURL,
        content: content,
      );

      _isLoading = false;
      notifyListeners();

      return commentId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> editComment({
    required String commentId,
    required String content,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.editComment(
        commentId: commentId,
        content: content,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteComment(
        commentId: commentId,
        postId: postId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> incrementPostViews(String postId) async {
    try {
      await _repository.incrementPostViews(postId);
    } catch (e) {
      // Silent fail for view tracking
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
