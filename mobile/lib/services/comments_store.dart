import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/comments/data/repositories/comments_api_repository.dart';
import 'package:flutter/material.dart';

class CommentsStore extends ChangeNotifier {
  CommentsStore({CommentsApiRepository? repository})
      : _repository = repository ?? CommentsApiRepository();

  final CommentsApiRepository _repository;

  final Map<String, List<CommentModel>> _commentsByUpdateId = {};
  final Set<String> _loadingUpdateIds = <String>{};
  String? _lastError;

  String? get lastError => _lastError;

  List<CommentModel> commentsForUpdate(String updateId) {
    return List.unmodifiable(_commentsByUpdateId[updateId] ?? const []);
  }

  bool isLoadingForUpdate(String updateId) => _loadingUpdateIds.contains(updateId);

  Future<void> fetchComments(String updateId, {bool force = false}) async {
    if (_loadingUpdateIds.contains(updateId)) return;
    if (!force && (_commentsByUpdateId[updateId]?.isNotEmpty ?? false)) return;

    _loadingUpdateIds.add(updateId);
    notifyListeners();

    try {
      final comments = await _repository.fetchComments(updateId);
      _commentsByUpdateId[updateId] = comments;
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _loadingUpdateIds.remove(updateId);
      notifyListeners();
    }
  }

  Future<void> createComment({
    required String updateId,
    required String content,
  }) async {
    final created =
        await _repository.createComment(updateId: updateId, content: content);
    if (created == null) return;

    final next = <CommentModel>[
      ...(_commentsByUpdateId[updateId] ?? const <CommentModel>[]),
      created,
    ];
    _commentsByUpdateId[updateId] = next;
    notifyListeners();
  }

  Future<void> updateComment({
    required String updateId,
    required String commentId,
    required String content,
  }) async {
    final updated = await _repository.updateComment(
      commentId: commentId,
      content: content,
    );
    if (updated == null) return;

    final items = <CommentModel>[
      ...(_commentsByUpdateId[updateId] ?? const <CommentModel>[]),
    ];
    final index = items.indexWhere((item) => item.id == commentId);
    if (index == -1) return;

    items[index] = updated;
    _commentsByUpdateId[updateId] = items;
    notifyListeners();
  }

  Future<void> deleteComment({
    required String updateId,
    required String commentId,
  }) async {
    final deleted = await _repository.deleteComment(commentId);
    if (!deleted) return;

    final items = <CommentModel>[
      ...(_commentsByUpdateId[updateId] ?? const <CommentModel>[]),
    ]
      ..removeWhere((item) => item.id == commentId);
    _commentsByUpdateId[updateId] = items;
    notifyListeners();
  }
}
