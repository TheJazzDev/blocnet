part of 'community_posts_store.dart';

mixin _CommunityPostsRealtimeMixin on ChangeNotifier {
  static const Duration _realtimeRefetchDebounce =
      Duration(milliseconds: 450);
  static const Duration _realtimeChannelRecoveryDelay = Duration(seconds: 2);

  RealtimeCoordinator get _realtimeCoordinator;
  Map<String, List<CommunityPostComment>> get _commentsByPostId;

  CommunityPost? postById(String postId);
  void _replacePost(CommunityPost post);
  Future<void> refreshLatestComments(String postId);
  Future<CommunityPost?> fetchPostById(String postId);
  List<CommunityPostComment> _mergeComments(
    List<CommunityPostComment> base,
    List<CommunityPostComment> incoming,
  );

  void _startCommentRealtimeChannel(String postId) {
    debugPrint('[RT][CommunityComment] subscribe start postId=$postId');
    final channel = Supabase.instance.client
        .channel('community-comments-$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'CommunityPostComment',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'postId',
            value: postId,
          ),
          callback: (payload) {
            debugPrint(
              '[RT][CommunityComment] insert received postId=$postId '
              'new=${payload.newRecord}',
            );
            final insertedNew = _applyRealtimeCommentInsert(
              postId,
              payload.newRecord,
            );
            _scheduleCommentsFallbackRefresh(postId);
            if (insertedNew) {
              _incrementPostCommentCount(postId);
            }
            _schedulePostRefresh(postId);
          },
        )
        .subscribe((status, [error]) {
      debugPrint(
        '[RT][CommunityComment] subscribe status postId=$postId '
        'status=$status error=$error',
      );
      _handleCommentSubscribeStatus(postId, status);
    });

    _realtimeCoordinator.trackChannel(postId, channel);
  }

  bool _applyRealtimeCommentInsert(
      String postId, Map<String, dynamic> newRecord) {
    final parsed = CommunityCommentSyncHelper.parseRealtimeComment(
      postId,
      newRecord,
    );
    if (parsed == null) {
      return false;
    }
    final existing =
        _commentsByPostId[postId] ?? const <CommunityPostComment>[];
    final alreadyPresent = existing.any((comment) => comment.id == parsed.id);
    _commentsByPostId[postId] = _mergeComments(existing, [parsed]);
    notifyListeners();
    return !alreadyPresent;
  }

  void _incrementPostCommentCount(String postId) {
    final post = postById(postId);
    if (post == null) return;
    _replacePost(post.copyWith(commentsCount: post.commentsCount + 1));
    notifyListeners();
  }

  void _scheduleCommentsFallbackRefresh(String postId) {
    _realtimeCoordinator.scheduleDebounce(
      'community-comment-refetch-$postId',
      delay: _realtimeRefetchDebounce,
      task: () => unawaited(refreshLatestComments(postId)),
    );
  }

  void _schedulePostRefresh(String postId) {
    _realtimeCoordinator.scheduleDebounce(
      'community-post-refresh-$postId',
      delay: _realtimeRefetchDebounce,
      task: () => unawaited(fetchPostById(postId)),
    );
  }

  void _handleCommentSubscribeStatus(
    String postId,
    RealtimeSubscribeStatus status,
  ) {
    _realtimeCoordinator.handleStatusWithRecovery(
      key: postId,
      status: status,
      recoveryDelay: _realtimeChannelRecoveryDelay,
      onSubscribed: () => unawaited(refreshLatestComments(postId)),
      onRecover: () async {
        _realtimeCoordinator.removeChannel(postId);
        _startCommentRealtimeChannel(postId);
        await refreshLatestComments(postId);
      },
    );
  }
}
