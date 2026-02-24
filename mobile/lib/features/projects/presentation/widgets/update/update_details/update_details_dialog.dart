import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
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
  late final CommentsStore _commentsStore;
  bool _isSubmittingComment = false;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    _commentsStore = context.read<CommentsStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _commentsStore.fetchComments(widget.id);
      _commentsStore.watchCommentsRealtime(widget.id);
    });
  }

  @override
  void dispose() {
    _commentsStore.unwatchCommentsRealtime(widget.id);
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
                      const SizedBox(height: 12),
                      _buildTipHunterAction(post),
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

  Widget _buildTipHunterAction(Update post) {
    final auth = context.watch<AuthStore>();
    final recipientUserId = post.adminId.toString().trim();
    if (recipientUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSelf = auth.userId != null && auth.userId == recipientUserId;
    if (isSelf) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          TipHunterSheet.show(
            context,
            recipient: TipRecipient(
              userId: recipientUserId,
              username: post.admin?.username,
              displayName: post.admin?.name,
              avatarUrl: post.admin?.imageUrl,
              isHunterHint: true,
            ),
            contextType: 'update',
            contextId: post.id.toString(),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(44),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
        label: const Text('Tip Hunter'),
      ),
    );
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary500.withValues(alpha: 0.15),
                        AppColors.primary500.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary500.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${comments.length}',
                    style: TextStyle(
                      color: AppColors.primary400,
                      fontSize: 11,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Comment input
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgElevated,
                    AppColors.bgElevated.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: 'Add a comment…',
                        hintStyle: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 13,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: isSubmitting ? null : onSubmit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.teal400, AppColors.primary500],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.teal400.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal400.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        isSubmitting ? '…' : 'Send',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated,
            AppColors.bgElevated.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.admin?.name ?? 'User',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (comment.admin?.primaryBadge != null) ...[
                const SizedBox(width: 4),
                BadgeIcon(
                  badge: comment.admin!.primaryBadge!,
                  size: BadgeSize.small,
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _relativeTime(comment.createdAt),
                  style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 10,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (canEdit) ...[
                InkWell(
                  onTap: () => _showEditDialog(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary400,
                        fontSize: 11,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () async {
                    await context.read<CommentsStore>().deleteComment(
                          updateId: updateId,
                          commentId: comment.id,
                        );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: AppColors.error500,
                        fontSize: 11,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
              height: 1.6,
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
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.borderSubtle.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          title: Text(
            'Edit comment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: TextField(
            controller: ctrl,
            minLines: 1,
            maxLines: 6,
            autofocus: true,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Edit your comment…',
              hintStyle: TextStyle(
                color: AppColors.textFaint,
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              fillColor: AppColors.bgElevated,
              filled: true,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                backgroundColor: AppColors.teal400.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.teal400,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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
