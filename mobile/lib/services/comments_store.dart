import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/comments/data/repositories/comments_api_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsStore extends ChangeNotifier {
  CommentsStore({CommentsApiRepository? repository})
      : _repository = repository ?? CommentsApiRepository();

  final CommentsApiRepository _repository;

  final Map<String, List<CommentModel>> _commentsByUpdateId = {};
  final Set<String> _loadingUpdateIds = <String>{};
  final Map<String, RealtimeChannel> _commentChannelsByUpdateId = {};
  String? _lastError;

  String? get lastError => _lastError;

  List<CommentModel> commentsForUpdate(String updateId) {
    return List.unmodifiable(_commentsByUpdateId[updateId] ?? const []);
  }

  bool isLoadingForUpdate(String updateId) =>
      _loadingUpdateIds.contains(updateId);

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

  void watchCommentsRealtime(String updateId) {
    if (!AppConfig.isSupabaseConfigured || updateId.isEmpty) return;
    if (_commentChannelsByUpdateId.containsKey(updateId)) return;

    debugPrint('[RT][Comment] subscribe start updateId=$updateId');
    final channel = Supabase.instance.client
        .channel('update-comments-$updateId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Comment',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'updateId',
            value: updateId,
          ),
          callback: (payload) {
            debugPrint(
              '[RT][Comment] insert received updateId=$updateId '
              'new=${payload.newRecord}',
            );
            unawaited(fetchComments(updateId, force: true));
          },
        )
        .subscribe((status, [error]) {
      debugPrint(
        '[RT][Comment] subscribe status updateId=$updateId '
        'status=$status error=$error',
      );
    });

    _commentChannelsByUpdateId[updateId] = channel;
  }

  void unwatchCommentsRealtime(String updateId) {
    final channel = _commentChannelsByUpdateId.remove(updateId);
    if (channel == null) return;
    debugPrint('[RT][Comment] unsubscribe updateId=$updateId');
    Supabase.instance.client.removeChannel(channel);
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
    ]..removeWhere((item) => item.id == commentId);
    _commentsByUpdateId[updateId] = items;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final channel in _commentChannelsByUpdateId.values) {
      Supabase.instance.client.removeChannel(channel);
    }
    _commentChannelsByUpdateId.clear();
    super.dispose();
  }
}
