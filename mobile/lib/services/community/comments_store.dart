import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/comments/data/repositories/comments_api_repository.dart';
import 'package:blocnet/shared/application/errors/store_error_mapper.dart';
import 'package:blocnet/shared/application/realtime/realtime_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsStore extends ChangeNotifier {
  CommentsStore({CommentsApiRepository? repository})
      : _repository = repository ?? CommentsApiRepository();

  static const int _pageSize = 40;
  static const Duration _refetchDebounce = Duration(milliseconds: 450);
  static const Duration _channelRecoveryDelay = Duration(seconds: 2);

  final CommentsApiRepository _repository;
  final StoreErrorMapper _errorMapper = const StoreErrorMapper();
  final RealtimeCoordinator _realtimeCoordinator = RealtimeCoordinator();

  final Map<String, List<CommentModel>> _commentsByUpdateId = {};
  final Map<String, bool> _hasMoreByUpdateId = {};
  final Set<String> _loadingUpdateIds = <String>{};
  String? _lastError;

  String? get lastError => _lastError;

  List<CommentModel> commentsForUpdate(String updateId) {
    return List.unmodifiable(_commentsByUpdateId[updateId] ?? const []);
  }

  bool isLoadingForUpdate(String updateId) =>
      _loadingUpdateIds.contains(updateId);

  bool hasMoreCommentsForUpdate(String updateId) =>
      _hasMoreByUpdateId[updateId] ?? true;

  Future<void> fetchComments(String updateId, {bool force = false}) async {
    if (_loadingUpdateIds.contains(updateId)) return;
    if (!force && (_commentsByUpdateId[updateId]?.isNotEmpty ?? false)) return;

    _loadingUpdateIds.add(updateId);
    notifyListeners();

    try {
      await _fetchLatestPage(updateId, replaceExisting: true);
      _lastError = null;
    } catch (error) {
      _lastError =
          _errorMapper.map(error, fallback: 'Unable to load comments');
    } finally {
      _loadingUpdateIds.remove(updateId);
      notifyListeners();
    }
  }

  Future<void> refreshLatestWindow(String updateId) async {
    if (_loadingUpdateIds.contains(updateId)) return;
    if (updateId.trim().isEmpty) return;

    try {
      await _fetchLatestPage(updateId, replaceExisting: false);
      _lastError = null;
      notifyListeners();
    } catch (error) {
      _lastError =
          _errorMapper.map(error, fallback: 'Unable to refresh comments');
      notifyListeners();
    }
  }

  Future<void> loadOlderComments(String updateId) async {
    if (_loadingUpdateIds.contains(updateId)) return;
    if (!hasMoreCommentsForUpdate(updateId)) return;

    final existing = _commentsByUpdateId[updateId] ?? const <CommentModel>[];
    if (existing.isEmpty) {
      await fetchComments(updateId, force: true);
      return;
    }

    final cursor = existing.first;
    _loadingUpdateIds.add(updateId);
    notifyListeners();
    try {
      final older = await _repository.fetchComments(
        updateId,
        limit: _pageSize,
        beforeCreatedAt: cursor.createdAt.toUtc().toIso8601String(),
        beforeId: cursor.id,
      );
      if (older.isEmpty) {
        _hasMoreByUpdateId[updateId] = false;
      } else {
        _commentsByUpdateId[updateId] = _mergeCommentLists(existing, older);
        _hasMoreByUpdateId[updateId] = older.length >= _pageSize;
      }
      _lastError = null;
    } catch (error) {
      _lastError =
          _errorMapper.map(error, fallback: 'Unable to load more comments');
    } finally {
      _loadingUpdateIds.remove(updateId);
      notifyListeners();
    }
  }

  Future<void> createComment({
    required String updateId,
    required String content,
    String? replyToId,
  }) async {
    final created = await _repository.createComment(
      updateId: updateId,
      content: content,
      replyToId: replyToId,
    );
    if (created == null) return;

    _commentsByUpdateId[updateId] = _mergeCommentLists(
      _commentsByUpdateId[updateId] ?? const <CommentModel>[],
      [created],
    );
    notifyListeners();
  }

  void watchCommentsRealtime(String updateId) {
    if (!AppConfig.isSupabaseConfigured || updateId.isEmpty) return;
    if (_realtimeCoordinator.hasChannel(updateId)) return;

    _startCommentRealtimeChannel(updateId);
  }

  void unwatchCommentsRealtime(String updateId) {
    _realtimeCoordinator.cancelDebounce(_refetchDebounceKey(updateId));
    _realtimeCoordinator.cancelRecovery(updateId);
    if (!_realtimeCoordinator.hasChannel(updateId)) return;
    debugPrint('[RT][Comment] unsubscribe updateId=$updateId');
    _realtimeCoordinator.removeChannel(updateId);
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

  Future<void> likeComment(String commentId) async {
    final updated = await _repository.likeComment(commentId);
    if (updated == null) return;

    // Update comment in all update caches that might contain it
    for (final updateId in _commentsByUpdateId.keys) {
      final items = <CommentModel>[
        ...(_commentsByUpdateId[updateId] ?? const <CommentModel>[]),
      ];
      final index = items.indexWhere((item) => item.id == commentId);
      if (index != -1) {
        items[index] = updated;
        _commentsByUpdateId[updateId] = items;
      }
    }
    notifyListeners();
  }

  Future<void> _fetchLatestPage(
    String updateId, {
    required bool replaceExisting,
  }) async {
    final latest = await _repository.fetchComments(updateId, limit: _pageSize);
    if (replaceExisting) {
      _commentsByUpdateId[updateId] = _sortComments(latest);
      _hasMoreByUpdateId[updateId] = latest.length >= _pageSize;
      return;
    }

    final existing = _commentsByUpdateId[updateId] ?? const <CommentModel>[];
    _commentsByUpdateId[updateId] = _mergeCommentLists(existing, latest);
    if (latest.length >= _pageSize) {
      _hasMoreByUpdateId[updateId] = true;
    }
  }

  void _startCommentRealtimeChannel(String updateId) {
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
            _applyRealtimeInsert(updateId, payload.newRecord);
            _scheduleFallbackRefresh(updateId);
          },
        )
        .subscribe((status, [error]) {
      debugPrint(
        '[RT][Comment] subscribe status updateId=$updateId '
        'status=$status error=$error',
      );
      _handleSubscribeStatus(updateId, status);
    });

    _realtimeCoordinator.trackChannel(updateId, channel);
  }

  void _applyRealtimeInsert(String updateId, Map<String, dynamic> newRecord) {
    final mapped = _parseRealtimeComment(updateId, newRecord);
    if (mapped == null) {
      _scheduleFallbackRefresh(updateId);
      return;
    }

    final existing = _commentsByUpdateId[updateId] ?? const <CommentModel>[];
    _commentsByUpdateId[updateId] = _mergeCommentLists(existing, [mapped]);
    notifyListeners();
  }

  CommentModel? _parseRealtimeComment(
    String updateId,
    Map<String, dynamic> newRecord,
  ) {
    try {
      final record = Map<String, dynamic>.from(newRecord);
      final status = (record['status'] ?? 'active').toString().toLowerCase();
      if (status != 'active') {
        return null;
      }
      record['updateId'] = record['updateId'] ?? updateId;

      final parsed = CommentModel.fromApi(record);
      if (parsed.id.trim().isEmpty || parsed.updateId.trim().isEmpty) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  void _scheduleFallbackRefresh(String updateId) {
    _realtimeCoordinator.scheduleDebounce(
      _refetchDebounceKey(updateId),
      delay: _refetchDebounce,
      task: () => unawaited(refreshLatestWindow(updateId)),
    );
  }

  void _handleSubscribeStatus(String updateId, RealtimeSubscribeStatus status) {
    _realtimeCoordinator.handleStatusWithRecovery(
      key: updateId,
      status: status,
      recoveryDelay: _channelRecoveryDelay,
      onSubscribed: () => unawaited(refreshLatestWindow(updateId)),
      onRecover: () async {
        _realtimeCoordinator.removeChannel(updateId);
        _startCommentRealtimeChannel(updateId);
        await refreshLatestWindow(updateId);
      },
    );
  }

  List<CommentModel> _mergeCommentLists(
    List<CommentModel> base,
    List<CommentModel> incoming,
  ) {
    final byId = <String, CommentModel>{};
    for (final item in base) {
      if (item.id.trim().isEmpty) continue;
      byId[item.id] = item;
    }

    for (final item in incoming) {
      if (item.id.trim().isEmpty) continue;
      final existing = byId[item.id];
      if (existing == null) {
        byId[item.id] = item;
        continue;
      }
      byId[item.id] = _mergeComment(existing, item);
    }

    return _sortComments(byId.values.toList(growable: false));
  }

  CommentModel _mergeComment(CommentModel existing, CommentModel incoming) {
    return CommentModel(
      id: existing.id,
      updateId: existing.updateId,
      authorId: incoming.authorId.trim().isNotEmpty
          ? incoming.authorId
          : existing.authorId,
      content: incoming.content.trim().isNotEmpty
          ? incoming.content
          : existing.content,
      createdAt: incoming.createdAt.isBefore(existing.createdAt)
          ? incoming.createdAt
          : existing.createdAt,
      updatedAt: incoming.updatedAt.isAfter(existing.updatedAt)
          ? incoming.updatedAt
          : existing.updatedAt,
      admin: incoming.admin ?? existing.admin,
    );
  }

  List<CommentModel> _sortComments(List<CommentModel> items) {
    items.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return items;
  }

  String _refetchDebounceKey(String updateId) => 'comments-refetch-$updateId';

  @override
  void dispose() {
    _realtimeCoordinator.dispose();
    super.dispose();
  }
}
