import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String? _postId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _postId = widget.postId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<CommunityPostsStore>();
      store.fetchPostsOnce();
      final id = _postId;
      if (id != null && id.isNotEmpty) {
        store.fetchPostById(id);
        store.fetchComments(id);
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
        store.fetchPostById(args);
        store.fetchComments(args);
      });
    }
  }

  @override
  void dispose() {
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
            style: GoogleFonts.inter(color: AppColors.textMuted),
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
          body: Column(
            children: [
              Expanded(
                child: post == null
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary400,
                          strokeWidth: 2,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        children: [
                          _PostDetailsCard(
                            post: post,
                            onLike: () => store.toggleLike(post.id),
                            onBookmark: () => store.toggleBookmark(post.id),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'DISCUSSION (${comments.length})',
                                style: GoogleFonts.inter(
                                  color: AppColors.textFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (comments.isEmpty)
                            _EmptyDiscussion()
                          else
                            ...comments.map((c) => _CommentCard(comment: c)),
                          const SizedBox(height: 90),
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
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textFaint,
                              fontSize: 13,
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.bgElevated,
                backgroundImage: (post.admin?.imageUrl.isNotEmpty ?? false)
                    ? NetworkImage(post.admin!.imageUrl)
                    : null,
                child: (post.admin?.imageUrl.isNotEmpty ?? false)
                    ? null
                    : Icon(Icons.person, size: 16, color: AppColors.textMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      getTimeStamp(post.createdAt),
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
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
                      style: GoogleFonts.inter(
                        color: post.isLiked
                            ? AppColors.warning500
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
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
        style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final CommunityPostComment comment;

  @override
  Widget build(BuildContext context) {
    final name = comment.admin?.name ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.bgElevated,
                backgroundImage: (comment.admin?.imageUrl.isNotEmpty ?? false)
                    ? NetworkImage(comment.admin!.imageUrl)
                    : null,
                child: (comment.admin?.imageUrl.isNotEmpty ?? false)
                    ? null
                    : Icon(Icons.person, size: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                getTimeStamp(comment.createdAt),
                style: GoogleFonts.inter(
                  color: AppColors.textFaint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
