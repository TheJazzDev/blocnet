import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/comments_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
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
      context.read<CommentsStore>().fetchComments(widget.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatesStore = Provider.of<UpdatesStore>(context);
    final matchingUpdates =
        updatesStore.updates.where((item) => item.id == widget.id).toList();
    if (matchingUpdates.isEmpty) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final post = matchingUpdates.first;

    if (post.project == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final moreFromProjectName = post.project?.posts ?? [];

    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.darkGrey100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                UpdateDetailsHeader(priority: post.priority),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        UpdateDetailsInfo(post: post),
                        const CustomHorizontalDivider(margin: 12),
                        UpdateDetailsTags(post),
                        const CustomHorizontalDivider(margin: 12),
                        RenderMarkdownContent(content: post.content),
                        const SizedBox(height: 20),
                        _CommentsSection(
                          updateId: widget.id,
                          controller: _commentController,
                          isSubmitting: _isSubmittingComment,
                          error: _commentError,
                          onSubmit: _createComment,
                        ),
                        const SizedBox(height: 28),
                        MoreFromProjectName(
                          label: 'More from',
                          projectTitle: post.project?.name ?? '',
                          posts: moreFromProjectName,
                        ),
                        const CustomHorizontalDivider(margin: 16),
                        const SizedBox(height: 16),
                        MoreFromUpdatePrimaryTag(
                          primaryTag:
                              post.project?.primaryTag ?? PrimaryTag.none,
                        ),
                        const SizedBox(height: 8),
                        const CustomHorizontalDivider(margin: 16),
                        const SizedBox(height: 8),
                        MoreFromUpdateSecondaryTags(post: post),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      setState(() {
        _commentError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _commentError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to comment: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }
}

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
                const StyledTitleLarge('Comments'),
                const SizedBox(width: 8),
                StyledBodyText500('${comments.length}', size: 12),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkGrey75,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkGrey200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(
                        color: AppColors.darkGrey700,
                        fontSize: 13,
                        fontFamily: 'Geist',
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add a comment',
                        hintStyle: TextStyle(
                          color: AppColors.darkGrey500,
                          fontSize: 12,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      isSubmitting ? '...' : 'Send',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (error != null && error!.isNotEmpty) ...[
              Text(
                error!,
                style: TextStyle(
                  color: AppColors.error500,
                  fontSize: 11,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isLoading && comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (comments.isEmpty)
              const StyledBodyText500('No comments yet', size: 12)
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkGrey75,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkGrey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StyledBodyText600(
                comment.admin?.name ?? 'User',
                size: 12,
              ),
              const SizedBox(width: 8),
              StyledBodyText500(_relativeTime(comment.createdAt), size: 11),
              const Spacer(),
              if (canEdit) ...[
                InkWell(
                  onTap: () => _showEditDialog(context),
                  child: StyledBodyText500('Edit', size: 11),
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
          StyledBodyText500(comment.content, size: 12),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: comment.content);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkGrey100,
          title: const Text('Edit comment'),
          content: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 6,
            style: TextStyle(color: AppColors.darkGrey700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final next = controller.text.trim();
                if (next.isEmpty) return;
                await context.read<CommentsStore>().updateComment(
                      updateId: updateId,
                      commentId: comment.id,
                      content: next,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  String _relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
