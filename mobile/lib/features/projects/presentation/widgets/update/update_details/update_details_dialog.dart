import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/comments_store.dart';
import 'package:blocnet/services/feed_view_mode_store.dart';
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
  const UpdateDetailsDialog({
    required this.id,
    this.focusCommentComposer = false,
    this.commentsOnly = false,
    super.key,
  });

  final String id;
  final bool focusCommentComposer;
  final bool commentsOnly;

  @override
  State<UpdateDetailsDialog> createState() => _PostDetailsDialogState();
}

class _PostDetailsDialogState extends State<UpdateDetailsDialog> {
  final TextEditingController _commentController =
      MentionHighlightTextController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsSectionKey = GlobalKey();
  late final CommentsStore _commentsStore;
  late final MentionsRepository _mentionsRepository;
  bool _isSubmittingComment = false;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    _commentsStore = context.read<CommentsStore>();
    _mentionsRepository = MentionsRepository(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _commentsStore.fetchComments(widget.id);
      _commentsStore.watchCommentsRealtime(widget.id);
      _focusCommentComposerIfRequested();
    });
  }

  @override
  void dispose() {
    _commentsStore.unwatchCommentsRealtime(widget.id);
    _scrollController.dispose();
    _commentFocusNode.dispose();
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
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final commentHeaderTitle = widget.commentsOnly
        ? 'Comments · ${post.project?.name ?? 'Update'}'
        : null;

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
              UpdateDetailsHeader(
                priority: post.priority,
                updateId: post.id,
                title: commentHeaderTitle,
                showPriority: !widget.commentsOnly,
              ),
              Expanded(
                child: widget.commentsOnly
                    ? SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _CommentsSection(
                          key: _commentsSectionKey,
                          updateId: widget.id,
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          mentionsRepository: _mentionsRepository,
                          isSubmitting: _isSubmittingComment,
                          error: _commentError,
                          viewMode: viewMode,
                          showHeading: false,
                          onSubmit: _createComment,
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
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
                              key: _commentsSectionKey,
                              updateId: widget.id,
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              mentionsRepository: _mentionsRepository,
                              isSubmitting: _isSubmittingComment,
                              error: _commentError,
                              viewMode: viewMode,
                              onSubmit: _createComment,
                            ),
                            const SizedBox(height: 32),
                            _Divider(),
                            const SizedBox(height: 20),
                            MoreFromProjectName(
                              label: 'More from',
                              projectTitle: post.project?.name ?? '',
                              posts: post.project?.posts ?? const [],
                            ),
                            const SizedBox(height: 16),
                            _Divider(),
                            const SizedBox(height: 16),
                            MoreFromUpdatePrimaryTag(
                              primaryTag:
                                  post.project?.primaryTag ?? PrimaryTag.none,
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

  Future<void> _focusCommentComposerIfRequested() async {
    if (!widget.focusCommentComposer) return;

    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;

    if (_scrollController.hasClients) {
      final targetOffset = (_scrollController.offset + 360).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    _commentFocusNode.requestFocus();
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
    super.key,
    required this.updateId,
    required this.controller,
    required this.focusNode,
    required this.mentionsRepository,
    required this.isSubmitting,
    required this.error,
    required this.viewMode,
    this.showHeading = true,
    required this.onSubmit,
  });

  final String updateId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final MentionsRepository mentionsRepository;
  final bool isSubmitting;
  final String? error;
  final FeedViewMode viewMode;
  final bool showHeading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    return Consumer<CommentsStore>(
      builder: (context, commentsStore, _) {
        final comments = commentsStore.commentsForUpdate(updateId);
        final isLoading = commentsStore.isLoadingForUpdate(updateId);
        final hasMore = commentsStore.hasMoreCommentsForUpdate(updateId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeading) ...[
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
            ],
            // Comment input
            Row(
              children: [
                Expanded(
                  child: MentionTextField(
                    controller: controller,
                    focusNode: focusNode,
                    mentionsRepository: mentionsRepository,
                    hintText: 'Add a comment…',
                    minLines: 4,
                    maxLines: 8,
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
            if (comments.isNotEmpty && hasMore)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => commentsStore.loadOlderComments(updateId),
                  child: Text(
                    isLoading ? 'Loading…' : 'Load older comments',
                    style: TextStyle(
                      color: AppColors.primary400,
                      fontSize: 12,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (comments.isNotEmpty && hasMore) const SizedBox(height: 8),
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
                children: comments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      _CommentTile(
                        comment: item,
                        canEdit: item.authorId == auth.userId,
                        updateId: updateId,
                        viewMode: viewMode,
                      ),
                      if (viewMode == FeedViewMode.list &&
                          index != comments.length - 1)
                        Divider(
                          height: 1,
                          color: AppColors.borderSubtle.withValues(alpha: 0.75),
                        ),
                    ],
                  );
                }).toList(),
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
    required this.viewMode,
  });

  final CommentModel comment;
  final bool canEdit;
  final String updateId;
  final FeedViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    final roleLabel = comment.admin?.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;
    final isCardMode = viewMode == FeedViewMode.card;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isCardMode ? 10 : 0),
      padding: EdgeInsets.fromLTRB(
        isCardMode ? 14 : 0,
        isCardMode ? 14 : 12,
        isCardMode ? 14 : 0,
        12,
      ),
      decoration: isCardMode
          ? BoxDecoration(
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
            )
          : null,
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
              if (roleLabel != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.8),
                      width: 0.8,
                    ),
                    color: roleColor.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 9,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
          MentionText(
            text: comment.content,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
            onMentionTap: (mentionUsername) async {
              await MentionProfileNavigator.openFromUsername(
                context,
                mentionUsername,
              );
            },
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
