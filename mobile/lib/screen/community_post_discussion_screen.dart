import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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
  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _threadScrollController = ScrollController();
  final Set<String> _knownCommentIds = <String>{};
  final Set<String> _pendingNewCommentIds = <String>{};
  String? _postId;
  bool _isSending = false;
  bool _isCommentsBaselineReady = false;
  VoidCallback? _storeListener;

  @override
  void initState() {
    super.initState();
    _postId = widget.postId;
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
    if (_postId != null && _postId!.isNotEmpty) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _postId = args;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final store = context.read<CommunityPostsStore>();
        _attachStoreListener();
        store.fetchPostById(args);
        store.fetchComments(args);
        store.watchCommentsRealtime(args);
      });
    }
  }

  void _attachStoreListener() {
    if (_storeListener != null) return;
    _storeListener = _onStoreChanged;
    context.read<CommunityPostsStore>().addListener(_storeListener!);
    _threadScrollController.addListener(_handleThreadScroll);
    _onStoreChanged();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final postId = _postId;
    if (postId == null || postId.isEmpty) return;

    final comments =
        context.read<CommunityPostsStore>().commentsForPost(postId);
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

    if (newIds.isEmpty) return;
    if (_isNearLatest()) return;

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
    final distanceToBottom = _threadScrollController.position.maxScrollExtent -
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
    final postId = _postId;
    if (postId != null && postId.isNotEmpty) {
      context.read<CommunityPostsStore>().unwatchCommentsRealtime(postId);
    }
    final listener = _storeListener;
    if (listener != null) {
      context.read<CommunityPostsStore>().removeListener(listener);
    }
    _threadScrollController
      ..removeListener(_handleThreadScroll)
      ..dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment(String postId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final created = await context.read<CommunityPostsStore>().createComment(
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
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: const CustomAppBar(
          title: 'Post Discussion',
          backButton: true,
          showSearch: false,
          showFilter: false,
        ),
        body: Center(
          child: Text(
            'No post selected.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 14,
              weight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Consumer<CommunityPostsStore>(
      builder: (context, store, _) {
        final post = store.postById(postId);
        final comments = store.commentsForPost(postId);

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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              children: [
                                _PostDetailsCard(
                                  post: post,
                                  onLike: () => store.toggleLike(post.id),
                                  onBookmark: () =>
                                      store.toggleBookmark(post.id),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Text(
                                      'DISCUSSION (${comments.length})',
                                      style: AppTypography.custom(
                                        color: AppColors.textFaint,
                                        size: 11,
                                        weight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (comments.isEmpty)
                                  _EmptyDiscussion()
                                else
                                  ...comments
                                      .map((c) => _CommentCard(comment: c)),
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
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                        top: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            style: AppTypography.custom(
                              color: AppColors.textSecondary,
                              size: 13,
                              weight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: AppTypography.custom(
                                color: AppColors.textFaint,
                                size: 13,
                                weight: FontWeight.w400,
                              ),
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSending ? null : () => _sendComment(postId),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostDetailsCard extends StatelessWidget {
  const _PostDetailsCard({
    required this.post,
    required this.onLike,
    required this.onBookmark,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  void _openAuthorProfile(BuildContext context) {
    final admin = post.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  @override
  Widget build(BuildContext context) {
    final adminName = post.admin?.name ?? 'Blocnet User';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openAuthorProfile(context),
                behavior: HitTestBehavior.opaque,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.bgElevated,
                  backgroundImage: (post.admin?.imageUrl.isNotEmpty ?? false)
                      ? NetworkImage(post.admin!.imageUrl)
                      : null,
                  child: (post.admin?.imageUrl.isNotEmpty ?? false)
                      ? null
                      : Icon(Icons.person,
                          size: 16, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openAuthorProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        adminName,
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      getTimeStamp(post.createdAt),
                      style: AppTypography.custom(color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w400,),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: AppTypography.custom(color: AppColors.textSecondary,
              size: 14,
              weight: FontWeight.w400,
              height: 1.55,),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: post.isLiked
                          ? AppColors.warning500
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likesCount}',
                      style: AppTypography.custom(
                        color: post.isLiked
                            ? AppColors.warning500
                            : AppColors.textMuted,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                '${post.commentsCount}',
                style: AppTypography.custom(color: AppColors.textMuted,
                  size: 13,
                  weight: FontWeight.w400,),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onBookmark,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  post.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 18,
                  color: post.isBookmarked
                      ? AppColors.primary400
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDiscussion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No comments yet. Start the discussion.',
        style: AppTypography.custom(color: AppColors.textMuted,
          size: 13,
          weight: FontWeight.w400,),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final CommunityPostComment comment;

  void _openAuthorProfile(BuildContext context) {
    final admin = comment.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  @override
  Widget build(BuildContext context) {
    final name = comment.admin?.name ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openAuthorProfile(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.15),
                    AppColors.primary500.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: (comment.admin?.imageUrl.isNotEmpty ?? false)
                  ? Image.network(
                      comment.admin!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(name),
                    )
                  : _avatarFallback(name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openAuthorProfile(context),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          name,
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      getTimeStamp(comment.createdAt),
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 13,
                    weight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        firstChar,
        style: AppTypography.custom(
          color: AppColors.primary400,
          size: 16,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}
