import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/comments_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommunityPostDiscussionScreen extends StatefulWidget {
  const CommunityPostDiscussionScreen({super.key, this.updateId});

  final String? updateId;

  @override
  State<CommunityPostDiscussionScreen> createState() =>
      _CommunityPostDiscussionScreenState();
}

class _CommunityPostDiscussionScreenState
    extends State<CommunityPostDiscussionScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  String? _updateId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _updateId = widget.updateId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UpdatesStore>().fetchUpdatesOnce();
      final id = _updateId;
      if (id != null && id.isNotEmpty) {
        context.read<CommentsStore>().fetchComments(id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_updateId != null && _updateId!.isNotEmpty) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _updateId = args;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CommentsStore>().fetchComments(args);
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment(String updateId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await context.read<CommentsStore>().createComment(
            updateId: updateId,
            content: text,
          );
      _commentCtrl.clear();
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
    final updateId = _updateId;
    if (updateId == null || updateId.isEmpty) {
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

    return Consumer2<UpdatesStore, CommentsStore>(
      builder: (context, updatesStore, commentsStore, _) {
        final post = _findPost(updatesStore.posts, updateId);
        final comments = commentsStore.commentsForUpdate(updateId);

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
                          _PostDetailsCard(post: post),
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
                        onTap: _isSending ? null : () => _sendComment(updateId),
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

  Update? _findPost(List<Update> posts, String updateId) {
    for (final post in posts) {
      if (post.id == updateId) return post;
    }
    return null;
  }
}

class _PostDetailsCard extends StatelessWidget {
  const _PostDetailsCard({required this.post});

  final Update post;

  @override
  Widget build(BuildContext context) {
    final adminName = post.admin?.name ?? 'Blocnet';

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
            post.title,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 26 - 6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.content.trim().isEmpty ? post.description : post.content,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_rounded,
                  size: 18, color: AppColors.warning500),
              const SizedBox(width: 5),
              Text(
                '${100 + (post.title.length % 90)}',
                style: GoogleFonts.inter(
                  color: AppColors.warning500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                '${12 + (post.description.length % 20)}',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.share_outlined, size: 18, color: AppColors.textMuted),
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

  final CommentModel comment;

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
