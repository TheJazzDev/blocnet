import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/comments_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../more_from/more_from_primary_tag.dart';
import '../../shared/more_from_project_name.dart';
import '../more_from/more_from_secondary_tags.dart';
import 'update_details_header.dart';
import 'update_details_info.dart';
import 'update_details_tags.dart';

class UpdateDetailsDialog extends StatefulWidget {
  const UpdateDetailsDialog({required this.id, super.key});

  final String id;

  @override
  State<UpdateDetailsDialog> createState() => _PostDetailsDialogState();
}

class _PostDetailsDialogState extends State<UpdateDetailsDialog> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final commentsStore = context.read<CommentsStore>();
      commentsStore.fetchComments(widget.id);
      commentsStore.watchCommentsRealtime(widget.id);
    });
  }

  @override
  void dispose() {
    context.read<CommentsStore>().unwatchCommentsRealtime(widget.id);
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatesStore = Provider.of<UpdatesStore>(context);
    final match = updatesStore.updates.where((u) => u.id == widget.id).toList();
    if (match.isEmpty) {
      return SafeArea(
        child:
            Center(child: CircularProgressIndicator(color: AppColors.teal400)),
      );
    }
    final post = match.first;
    if (post.project == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.teal400));
    }

    final moreFromProjectName = post.project?.posts ?? [];

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              UpdateDetailsHeader(priority: post.priority),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      UpdateDetailsInfo(post: post),
                      const SizedBox(height: 16),
                      _Divider(),
                      const SizedBox(height: 12),
                      UpdateDetailsTags(post),
                      const SizedBox(height: 12),
                      _Divider(),
                      const SizedBox(height: 16),
                      RenderMarkdownContent(content: post.content),
                      const SizedBox(height: 24),
                      _CommentsSection(
                        updateId: widget.id,
                        controller: _commentController,
                        isSubmitting: _isSubmittingComment,
                        error: _commentError,
                        onSubmit: _createComment,
                      ),
                      const SizedBox(height: 32),
                      _Divider(),
                      const SizedBox(height: 20),
                      MoreFromProjectName(
                        label: 'More from',
                        projectTitle: post.project?.name ?? '',
                        posts: moreFromProjectName,
                      ),
                      const SizedBox(height: 16),
                      _Divider(),
                      const SizedBox(height: 16),
                      MoreFromUpdatePrimaryTag(
                        primaryTag: post.project?.primaryTag ?? PrimaryTag.none,
                      ),
                      const SizedBox(height: 8),
                      _Divider(),
                      const SizedBox(height: 8),
                      MoreFromUpdateSecondaryTags(post: post),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment) return;

    setState(() => _isSubmittingComment = true);
    try {
      await context.read<CommentsStore>().createComment(
            updateId: widget.id,
            content: content,
          );
      _commentController.clear();
      setState(() => _commentError = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _commentError = error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to comment: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.borderSubtle);
  }
}

// ─── Comments Section ─────────────────────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.updateId,
    required this.controller,
    required this.isSubmitting,
    required this.error,
    required this.onSubmit,
  });

  final String updateId;
  final TextEditingController controller;
  final bool isSubmitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    return Consumer<CommentsStore>(
      builder: (context, commentsStore, _) {
        final comments = commentsStore.commentsForUpdate(updateId);
        final isLoading = commentsStore.isLoadingForUpdate(updateId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${comments.length}',
                    style: TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 11,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Comment input
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontFamily: 'Geist',
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add a comment…',
                        hintStyle: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 13,
                          fontFamily: 'Geist',
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isSubmitting ? null : onSubmit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.teal500, AppColors.primary500],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSubmitting ? '…' : 'Send',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null && error!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                error!,
                style: TextStyle(
                  color: AppColors.error500,
                  fontSize: 11,
                  fontFamily: 'Geist',
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isLoading && comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.teal400,
                  ),
                ),
              )
            else if (comments.isEmpty)
              Text(
                'No comments yet',
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              )
            else
              Column(
                children: comments
                    .map(
                      (item) => _CommentTile(
                        comment: item,
                        canEdit: item.authorId == auth.userId,
                        updateId: updateId,
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

// ─── Comment Tile ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canEdit,
    required this.updateId,
  });

  final CommentModel comment;
  final bool canEdit;
  final String updateId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.admin?.name ?? 'User',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _relativeTime(comment.createdAt),
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                  fontFamily: 'Geist',
                ),
              ),
              const Spacer(),
              if (canEdit) ...[
                InkWell(
                  onTap: () => _showEditDialog(context),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () async {
                    await context.read<CommentsStore>().deleteComment(
                          updateId: updateId,
                          commentId: comment.id,
                        );
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: AppColors.error500,
                      fontSize: 11,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.content,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: comment.content);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
          title: Text(
            'Edit comment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: ctrl,
            minLines: 1,
            maxLines: 6,
            style:
                TextStyle(color: AppColors.textSecondary, fontFamily: 'Geist'),
            decoration: InputDecoration(
              hintText: 'Edit your comment…',
              hintStyle:
                  TextStyle(color: AppColors.textFaint, fontFamily: 'Geist'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.teal500),
              ),
              fillColor: AppColors.bgElevated,
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: AppColors.textMuted, fontFamily: 'Geist'),
              ),
            ),
            TextButton(
              onPressed: () async {
                final next = ctrl.text.trim();
                if (next.isEmpty) return;
                await context.read<CommentsStore>().updateComment(
                      updateId: updateId,
                      commentId: comment.id,
                      content: next,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: TextStyle(
                    color: AppColors.teal400,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    ctrl.dispose();
  }

  String _relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
