import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_composer.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_no_post_view.dart';
import 'package:blocnet/features/community/presentation/widgets/discussion/discussion_body.dart';
import 'package:blocnet/features/community/presentation/widgets/discussion/discussion_thread_list.dart';
import 'package:blocnet/features/community/presentation/widgets/feed/community_save_toggle.dart';
import 'package:blocnet/features/community/presentation/widgets/moderation/moderation_actions.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_author_line.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A community post and its comments, with a composer pinned to the bottom.
///
/// Opened with the post id, or `{postId, focusComposer}` as route arguments.
class CommunityPostDiscussionScreen extends StatefulWidget {
  const CommunityPostDiscussionScreen({super.key, this.postId});

  final String? postId;

  @override
  State<CommunityPostDiscussionScreen> createState() =>
      _CommunityPostDiscussionScreenState();
}

class _CommunityPostDiscussionScreenState
    extends State<CommunityPostDiscussionScreen> {
  final TextEditingController _commentCtrl = MentionHighlightTextController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scroll = ScrollController();
  final Set<String> _knownCommentIds = <String>{};
  final Set<String> _pendingCommentIds = <String>{};
  final MentionsRepository _mentionsRepository =
      MentionsRepository(ApiClient());
  final CommunityModerationApiRepository _moderationRepository =
      CommunityModerationApiRepository();

  CommunityPostsStore? _store;
  String? _postId;
  bool _baselineReady = false;
  bool _isSending = false;
  CommunityPostComment? _replyTo;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_handleScroll);
    final id = widget.postId;
    if (id != null && id.isNotEmpty) _openThread(id, focusComposer: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store ??= context.read<CommunityPostsStore>()
      ..addListener(_onStoreChanged);
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = switch (args) {
      String value => value,
      Map value => value['postId']?.toString(),
      _ => null,
    };
    if (id == null || id.isEmpty || id == _postId) return;
    _openThread(
      id,
      focusComposer: args is Map && args['focusComposer'] == true,
    );
  }

  void _openThread(String postId, {required bool focusComposer}) {
    final previous = _postId;
    _postId = postId;
    _baselineReady = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = _store ?? context.read<CommunityPostsStore>();
      if (previous != null) store.unwatchCommentsRealtime(previous);
      store.fetchPostById(postId);
      store.fetchComments(postId);
      store.watchCommentsRealtime(postId);
      _onStoreChanged();
      if (focusComposer) _focusComposerSoon();
    });
  }

  /// Notes comments that arrive while the reader is scrolled away from the
  /// bottom, so a pill can offer to jump to them.
  void _onStoreChanged() {
    final postId = _postId;
    final store = _store;
    if (!mounted || postId == null || store == null) return;
    final ids = store.commentsForPost(postId).map((c) => c.id).toSet();
    if (!_baselineReady) {
      _knownCommentIds
        ..clear()
        ..addAll(ids);
      _baselineReady = !store.isLoadingCommentsForPost(postId);
      return;
    }
    final fresh = ids.difference(_knownCommentIds);
    _knownCommentIds
      ..clear()
      ..addAll(ids);
    if (fresh.isEmpty || _isNearBottom()) return;
    setState(() => _pendingCommentIds.addAll(fresh));
  }

  void _handleScroll() {
    if (_pendingCommentIds.isNotEmpty && _isNearBottom()) {
      setState(_pendingCommentIds.clear);
    }
  }

  bool _isNearBottom() {
    if (!_scroll.hasClients) return true;
    final position = _scroll.position;
    return position.maxScrollExtent - position.pixels <= 80;
  }

  Future<void> _jumpToNewest() async {
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(_pendingCommentIds.clear);
  }

  @override
  void dispose() {
    final store = _store;
    final postId = _postId;
    if (store != null) {
      store.removeListener(_onStoreChanged);
      if (postId != null) store.unwatchCommentsRealtime(postId);
    }
    _scroll
      ..removeListener(_handleScroll)
      ..dispose();
    _commentFocusNode.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _focusComposerSoon() {
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _commentFocusNode.requestFocus();
    });
  }

  void _replyToComment(CommunityPostComment comment) {
    setState(() => _replyTo = comment);
    _commentFocusNode.requestFocus();
  }

  Future<void> _send(String postId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      final created = await _store!.createComment(
        postId: postId,
        content: text,
        replyToId: _replyTo?.id,
      );
      if (created != null && mounted) {
        _commentCtrl.clear();
        setState(() => _replyTo = null);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          describeApiError(error, fallback: 'Could not send comment'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postId = _postId;
    if (postId == null || postId.isEmpty) {
      return const CommunityDiscussionNoPostView();
    }

    final auth = context.watch<AuthStore>();
    final store = context.watch<CommunityPostsStore>();
    final post = store.postById(postId);
    final canModerate = auth.canAccessCommunityStaffTools;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Post',
        showSearch: false,
        showFilter: false,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: DiscussionBody(
                hasPost: post != null,
                loadError: store.postLoadError(postId),
                onRetry: () => store.fetchPostById(postId),
                pendingCount: _pendingCommentIds.length,
                onJumpToNewest: _jumpToNewest,
                thread: post == null
                    ? null
                    : DiscussionThreadList(
                        post: post,
                        comments: store.commentsForPost(postId),
                        controller: _scroll,
                        isLoadingComments:
                            store.isLoadingCommentsForPost(postId),
                        hasMoreComments: store.hasMoreCommentsForPost(postId),
                        commentsError: store.commentsError(postId),
                        onLoadOlder: () => store.loadOlderComments(postId),
                        onRetryComments: () =>
                            store.fetchComments(postId, force: true),
                        onLikePost: () => store.toggleLike(postId),
                        onSavePost: () => toggleCommunitySave(context, postId),
                        onCommentTap: _commentFocusNode.requestFocus,
                        onLikeComment: (c) =>
                            store.toggleLikeCommunityPostComment(c.id),
                        onReply: _replyToComment,
                        canArchiveModeration: auth.isCommunityAdmin,
                        onModeratePost: !canModerate
                            ? null
                            : (decision) async {
                                final ok = await applyPostModeration(
                                  context,
                                  repository: _moderationRepository,
                                  postId: postId,
                                  decision: decision,
                                );
                                if (ok &&
                                    context.mounted &&
                                    store.postById(postId) == null) {
                                  Navigator.of(context).maybePop();
                                }
                              },
                        onModerateComment: !canModerate
                            ? null
                            : (commentId, decision) => applyCommentModeration(
                                  context,
                                  repository: _moderationRepository,
                                  postId: postId,
                                  commentId: commentId,
                                  decision: decision,
                                ),
                      ),
              ),
            ),
            if (post != null)
              CommunityDiscussionComposer(
                controller: _commentCtrl,
                focusNode: _commentFocusNode,
                mentionsRepository: _mentionsRepository,
                isSending: _isSending,
                onSendTap: () => _send(postId),
                replyingToUsername: _replyTo == null
                    ? null
                    : communityHandle(_replyTo!.admin).substring(1),
                onCancelReply: () => setState(() => _replyTo = null),
              ),
          ],
        ),
      ),
    );
  }
}
