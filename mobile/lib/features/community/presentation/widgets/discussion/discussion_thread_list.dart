import 'dart:math' as math;

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/application/community_comment_threading.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_comment_card.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_post_details_card.dart';
import 'package:blocnet/features/community/presentation/widgets/discussion/discussion_header.dart';
import 'package:flutter/material.dart';

typedef CommentModeration = Future<void> Function(
  String commentId,
  CommunityContentModerationDecision decision,
);

/// The scrolling part of a discussion: the post, the comment count, then the
/// thread (or its empty / failed line).
class DiscussionThreadList extends StatelessWidget {
  const DiscussionThreadList({
    super.key,
    required this.post,
    required this.comments,
    required this.controller,
    required this.isLoadingComments,
    required this.hasMoreComments,
    required this.commentsError,
    required this.onLoadOlder,
    required this.onRetryComments,
    required this.onLikePost,
    required this.onSavePost,
    required this.onCommentTap,
    required this.onLikeComment,
    required this.onReply,
    this.onModeratePost,
    this.onModerateComment,
    this.canArchiveModeration = false,
  });

  final CommunityPost post;
  final List<CommunityPostComment> comments;
  final ScrollController controller;
  final bool isLoadingComments;
  final bool hasMoreComments;
  final String? commentsError;
  final VoidCallback onLoadOlder;
  final VoidCallback onRetryComments;
  final VoidCallback onLikePost;
  final VoidCallback onSavePost;
  final VoidCallback onCommentTap;
  final ValueChanged<CommunityPostComment> onLikeComment;
  final ValueChanged<CommunityPostComment> onReply;
  final Future<void> Function(CommunityContentModerationDecision decision)?
      onModeratePost;
  final CommentModeration? onModerateComment;
  final bool canArchiveModeration;

  @override
  Widget build(BuildContext context) {
    final thread = threadCommunityComments(comments);
    // The post's own count covers pages not loaded yet; the loaded list can
    // briefly be ahead of it after a new comment arrives.
    final count = math.max(post.commentsCount, comments.length);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.xxxl,
      ),
      children: [
        CommunityDiscussionPostDetailsCard(
          post: post,
          onLike: onLikePost,
          onCommentTap: onCommentTap,
          onBookmark: onSavePost,
          onModerate: onModeratePost,
          canArchiveModeration: canArchiveModeration,
        ),
        const SizedBox(height: AppSpace.lg),
        DiscussionHeader(
          count: count,
          isLoading: isLoadingComments,
          hasMore: hasMoreComments,
          onLoadOlder: onLoadOlder,
        ),
        const SizedBox(height: AppSpace.xs),
        if (thread.isEmpty)
          isLoadingComments
              ? const Padding(
                  padding: EdgeInsets.all(AppSpace.xl),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : CommunityDiscussionEmpty(
                  error: commentsError,
                  onRetry: onRetryComments,
                )
        else
          for (var i = 0; i < thread.length; i++) ...[
            if (i > 0 && !thread[i].isNestedReply)
              const Divider(height: 1, color: AppColors.borderSubtle),
            _commentTile(thread[i]),
          ],
      ],
    );
  }

  Widget _commentTile(ThreadedCommunityComment item) {
    final comment = item.comment;
    return CommunityDiscussionCommentCard(
      key: ValueKey('comment-${comment.id}'),
      comment: comment,
      isNestedReply: item.isNestedReply,
      onReply: () => onReply(comment),
      onLike: () => onLikeComment(comment),
      onModerate: onModerateComment == null
          ? null
          : (decision) => onModerateComment!(comment.id, decision),
      canArchiveModeration: canArchiveModeration,
    );
  }
}
