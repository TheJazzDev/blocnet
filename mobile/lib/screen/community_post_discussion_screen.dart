import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
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
  final TextEditingController _commentCtrl = MentionHighlightTextController();
  final ScrollController _threadScrollController = ScrollController();
  final Set<String> _knownCommentIds = <String>{};
  final Set<String> _pendingNewCommentIds = <String>{};
  late final MentionsRepository _mentionsRepository;
  String? _postId;
  bool _isSending = false;
  bool _isCommentsBaselineReady = false;
  VoidCallback? _storeListener;

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
                                else ...[
                                  for (var index = 0;
                                      index < comments.length;
                                      index++) ...[
                                    _CommentCard(comment: comments[index]),
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
                          child: MentionTextField(
                            controller: _commentCtrl,
                            mentionsRepository: _mentionsRepository,
                            hintText: 'Write a comment...',
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 300,
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
    final admin = post.admin;
    final adminName =
        admin?.name.trim().isNotEmpty == true ? admin!.name : 'Blocnet User';
    final username = _formatUsername(
      admin?.username,
      fallbackName: adminName,
    );
    final roleLabel = admin?.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openAuthorProfile(context),
                behavior: HitTestBehavior.opaque,
                child: AppAvatar(
                  radius: 20,
                  imageUrl: post.admin?.imageUrl,
                  fallback: Text(
                    adminName[0].toUpperCase(),
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openAuthorProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              adminName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.custom(
                                color: AppColors.textPrimary,
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (admin?.primaryBadge != null) ...[
                            const SizedBox(width: 6),
                            BadgeIcon(
                              badge: admin!.primaryBadge!,
                              size: BadgeSize.small,
                              showTooltip: false,
                            ),
                          ],
                          if (roleLabel != null) ...[
                            const SizedBox(width: 6),
                            _RolePill(
                              label: roleLabel,
                              color: roleColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 12,
                        weight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      getTimeStamp(post.createdAt),
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MentionText(
            text: post.content,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 14,
              weight: FontWeight.w400,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DiscussionAction(
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  value: '${post.likesCount}',
                  color:
                      post.isLiked ? AppColors.warning500 : AppColors.textMuted,
                  onTap: onLike,
                ),
              ),
              Expanded(
                child: _DiscussionAction(
                  icon: Icons.mode_comment_outlined,
                  value: '${post.commentsCount}',
                  color: AppColors.textMuted,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _DiscussionAction(
                  icon: post.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  value: '',
                  color: post.isBookmarked
                      ? AppColors.primary400
                      : AppColors.textMuted,
                  onTap: onBookmark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  String _formatUsername(String? value, {required String fallbackName}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized.startsWith('@') ? normalized : '@$normalized';
    }

    final fallback = fallbackName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (fallback.isEmpty) return '@member';
    return '@$fallback';
  }
}

class _DiscussionAction extends StatelessWidget {
  const _DiscussionAction({
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              if (value.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  value,
                  style: AppTypography.custom(
                    color: color,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
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
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: 13,
          weight: FontWeight.w400,
        ),
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
    final admin = comment.admin;
    final name = admin?.name.trim().isNotEmpty == true ? admin!.name : 'User';
    final username = _formatUsername(
      admin?.username,
      fallbackName: name,
    );
    final roleLabel = admin?.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openAuthorProfile(context),
            behavior: HitTestBehavior.opaque,
            child: AppAvatar(
              radius: 18,
              imageUrl: comment.admin?.imageUrl,
              fallback: _avatarFallback(name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _openAuthorProfile(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.custom(
                                  color: AppColors.textPrimary,
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (admin?.primaryBadge != null) ...[
                              const SizedBox(width: 6),
                              BadgeIcon(
                                badge: admin!.primaryBadge!,
                                size: BadgeSize.small,
                                showTooltip: false,
                              ),
                            ],
                            if (roleLabel != null) ...[
                              const SizedBox(width: 6),
                              _RolePill(
                                label: roleLabel,
                                color: roleColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 2),
                Text(
                  username,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                MentionText(
                  text: comment.content,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 13,
                    weight: FontWeight.w400,
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
    return Text(
      firstChar,
      style: AppTypography.custom(
        color: AppColors.primary400,
        size: 15,
        weight: FontWeight.w700,
      ),
    );
  }

  String _formatUsername(String? value, {required String fallbackName}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized.startsWith('@') ? normalized : '@$normalized';
    }

    final fallback = fallbackName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (fallback.isEmpty) return '@member';
    return '@$fallback';
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 0.8),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
