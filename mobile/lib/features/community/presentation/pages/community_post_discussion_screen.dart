import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_comment_card.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_composer.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_no_post_view.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_post_details_card.dart';
import 'package:blocnet/features/community/presentation/widgets/community_post_share_sheet.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final ScrollController _threadScrollController = ScrollController();
  final Set<String> _knownCommentIds = <String>{};
  final Set<String> _pendingNewCommentIds = <String>{};
  late final MentionsRepository _mentionsRepository;
  String? _postId;
  bool _focusComposerOnLoad = false;
  bool _isSending = false;
  bool _isCommentsBaselineReady = false;
  VoidCallback? _storeListener;
  CommunityPostsStore? _communityPostsStore;

  @override
  void initState() {
    super.initState();
    _postId = widget.postId;
    _mentionsRepository = MentionsRepository(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<CommunityPostsStore>();
      store.fetchPostsOnce();
      _attachStoreListener();
      final id = _postId;
      if (id != null && id.isNotEmpty) {
        store.fetchPostById(id);
        store.fetchComments(id);
        store.watchCommentsRealtime(id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _communityPostsStore ??= context.read<CommunityPostsStore>();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      if (_postId == args) return;
      _loadThread(postId: args, focusComposer: false);
      return;
    }

    if (args is Map) {
      final postId = args['postId']?.toString();
      if (postId == null || postId.isEmpty || _postId == postId) {
        return;
      }
      _loadThread(postId: postId, focusComposer: args['focusComposer'] == true);
    }
  }

  void _loadThread({
    required String postId,
    required bool focusComposer,
  }) {
    _postId = postId;
    _focusComposerOnLoad = focusComposer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = _communityPostsStore ?? context.read<CommunityPostsStore>();
      _attachStoreListener();
      store.fetchPostById(postId);
      store.fetchComments(postId);
      store.watchCommentsRealtime(postId);
      if (_focusComposerOnLoad) {
        _focusComposerSoon();
      }
    });
  }

  void _attachStoreListener() {
    if (_storeListener != null) return;
    final store = _communityPostsStore;
    if (store == null) return;
    _storeListener = _onStoreChanged;
    store.addListener(_storeListener!);
    _threadScrollController.addListener(_handleThreadScroll);
    _onStoreChanged();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final postId = _postId;
    if (postId == null || postId.isEmpty) return;

    final store = _communityPostsStore;
    if (store == null) return;
    final comments = store.commentsForPost(postId);
    final currentIds = comments.map((comment) => comment.id).toSet();

    if (!_isCommentsBaselineReady) {
      _knownCommentIds
        ..clear()
        ..addAll(currentIds);
      _isCommentsBaselineReady = true;
      return;
    }

    final newIds = currentIds.difference(_knownCommentIds);
    _knownCommentIds
      ..clear()
      ..addAll(currentIds);

    if (newIds.isEmpty || _isNearLatest()) return;

    setState(() {
      _pendingNewCommentIds.addAll(newIds);
    });
  }

  void _handleThreadScroll() {
    if (_isNearLatest() && _pendingNewCommentIds.isNotEmpty) {
      setState(() => _pendingNewCommentIds.clear());
    }
  }

  bool _isNearLatest() {
    if (!_threadScrollController.hasClients) return true;
    final distanceToBottom =
        _threadScrollController.position.maxScrollExtent -
            _threadScrollController.offset;
    return distanceToBottom <= 80;
  }

  Future<void> _jumpToLatestComments() async {
    if (_threadScrollController.hasClients) {
      await _threadScrollController.animateTo(
        _threadScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _pendingNewCommentIds.clear());
  }

  @override
  void dispose() {
    final store = _communityPostsStore;
    final postId = _postId;
    if (store != null && postId != null && postId.isNotEmpty) {
      store.unwatchCommentsRealtime(postId);
    }
    final listener = _storeListener;
    if (store != null && listener != null) {
      store.removeListener(listener);
    }
    _threadScrollController
      ..removeListener(_handleThreadScroll)
      ..dispose();
    _commentFocusNode.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _focusComposerSoon() {
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _commentFocusNode.requestFocus();
    });
  }

  Future<void> _sendComment(String postId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    if (text.length > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community comments cannot exceed 300 characters'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final store = _communityPostsStore ?? context.read<CommunityPostsStore>();
      final created = await store.createComment(
        postId: postId,
        content: text,
      );

      if (created != null) {
        _commentCtrl.clear();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment')),
      );
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

    return Consumer<CommunityPostsStore>(
      builder: (context, store, _) {
        final post = store.postById(postId);
        final comments = store.commentsForPost(postId);
        final isLoadingComments = store.isLoadingCommentsForPost(postId);
        final hasMoreComments = store.hasMoreCommentsForPost(postId);

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: const CustomAppBar(
            title: 'Post Details',
            backButton: true,
            showSearch: false,
            showFilter: false,
          ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                Expanded(
                  child: post == null
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary400,
                            strokeWidth: 2,
                          ),
                        )
                      : Stack(
                          children: [
                            ListView(
                              controller: _threadScrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              children: [
                                CommunityDiscussionPostDetailsCard(
                                  post: post,
                                  onLike: () => store.toggleLike(post.id),
                                  onCommentTap: _focusComposerSoon,
                                  onShareTap: () => _openShareSheet(post),
                                  onBookmark: () => store.toggleBookmark(post.id),
                                ),
                                const SizedBox(height: 14),
                                _DiscussionHeader(
                                  commentsCount: comments.length,
                                  isLoadingComments: isLoadingComments,
                                  hasMoreComments: hasMoreComments,
                                  onLoadOlder: () => store.loadOlderComments(postId),
                                ),
                                const SizedBox(height: 10),
                                if (comments.isEmpty)
                                  const CommunityDiscussionEmpty()
                                else ...[
                                  for (var index = 0;
                                      index < comments.length;
                                      index++) ...[
                                    CommunityDiscussionCommentCard(
                                      comment: comments[index],
                                    ),
                                    if (index != comments.length - 1)
                                      Divider(
                                        height: 1,
                                        color: AppColors.borderSubtle
                                            .withValues(alpha: 0.8),
                                      ),
                                  ],
                                ],
                                const SizedBox(height: 90),
                              ],
                            ),
                            if (_pendingNewCommentIds.isNotEmpty)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _jumpToLatestComments,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary500,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${_pendingNewCommentIds.length} new comments',
                                        style: AppTypography.custom(
                                          color: Colors.black,
                                          size: 12,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                CommunityDiscussionComposer(
                  controller: _commentCtrl,
                  focusNode: _commentFocusNode,
                  mentionsRepository: _mentionsRepository,
                  isSending: _isSending,
                  onSendTap: () => _sendComment(postId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openShareSheet(CommunityPost post) async {
    await showCommunityPostShareSheet(
      context,
      postId: post.id,
      content: post.content,
    );
  }
}

class _DiscussionHeader extends StatelessWidget {
  const _DiscussionHeader({
    required this.commentsCount,
    required this.isLoadingComments,
    required this.hasMoreComments,
    required this.onLoadOlder,
  });

  final int commentsCount;
  final bool isLoadingComments;
  final bool hasMoreComments;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'DISCUSSION ($commentsCount)',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
            weight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (commentsCount > 0 && hasMoreComments)
          TextButton(
            onPressed: isLoadingComments ? null : onLoadOlder,
            child: Text(
              isLoadingComments ? 'Loading…' : 'Load older',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
