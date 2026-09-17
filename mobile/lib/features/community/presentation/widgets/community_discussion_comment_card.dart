import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/discussion/comment_reply_quote.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_author_line.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_content_menu.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_post_actions.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:flutter/material.dart';

export 'package:blocnet/features/community/presentation/widgets/discussion/community_discussion_empty.dart';

/// One comment in a discussion. A reply sits indented under its parent with a
/// hairline on its left.
class CommunityDiscussionCommentCard extends StatelessWidget {
  const CommunityDiscussionCommentCard({
    super.key,
    required this.comment,
    this.isNestedReply = false,
    this.onReply,
    this.onLike,
    this.onModerate,
    this.canArchiveModeration = false,
  });

  final CommunityPostComment comment;
  final bool isNestedReply;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final Future<void> Function(CommunityContentModerationDecision decision)?
      onModerate;
  final bool canArchiveModeration;

  void _openAuthor(BuildContext context) {
    final author = comment.admin;
    if (author == null) return;
    PublicProfileScreen.showSheet(context, author);
  }

  Future<void> _moderate(BuildContext context) async {
    final decision = await showCommunityContentModerationSheet(
      context,
      targetLabel: 'comment',
      canArchive: canArchiveModeration,
    );
    if (decision == null) return;
    await onModerate?.call(decision);
  }

  @override
  Widget build(BuildContext context) {
    final hasMenu = communityMenuHasItems(
      context,
      author: comment.admin,
      canModerate: onModerate != null,
    );
    final parent = comment.replyToData;

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityAvatar(
          author: comment.admin,
          radius: 16,
          onTap: () => _openAuthor(context),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityAuthorLine(
                author: comment.admin,
                createdAt: comment.createdAt,
                status: comment.status,
                onTap: () => _openAuthor(context),
                trailing: hasMenu
                    ? CommunityMoreButton(
                        onTap: () => showCommunityContentMenu(
                          context,
                          targetType:
                              CommunityReportTargetType.communityComment,
                          targetId: comment.id,
                          content: comment.content,
                          author: comment.admin,
                          onModerate: onModerate == null
                              ? null
                              : () => _moderate(context),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpace.sm),
              if (!isNestedReply && parent != null) ...[
                CommentReplyQuote(parent: parent),
                const SizedBox(height: AppSpace.sm),
              ],
              MentionText(
                text: comment.content,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
                onMentionTap: (username) =>
                    MentionProfileNavigator.openFromUsername(context, username),
              ),
              const SizedBox(height: AppSpace.xs),
              _CommentActions(
                comment: comment,
                onLike: onLike,
                onReply: onReply,
              ),
            ],
          ),
        ),
      ],
    );

    if (!isNestedReply) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: body,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.xl),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.md,
          0,
          AppSpace.md,
        ),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.borderSubtle, width: 2),
          ),
        ),
        child: body,
      ),
    );
  }
}

class _CommentActions extends StatelessWidget {
  const _CommentActions({
    required this.comment,
    required this.onLike,
    required this.onReply,
  });

  final CommunityPostComment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    if (onLike == null && onReply == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (onLike != null)
          CommunityActionButton(
            icon: comment.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconSize: AppIcon.sm,
            color: comment.isLiked ? AppColors.primary400 : AppColors.textMuted,
            count: comment.likesCount,
            label: comment.isLiked ? 'Unlike' : 'Like',
            onTap: onLike!,
          ),
        if (onReply != null) ...[
          const SizedBox(width: AppSpace.md),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: onReply,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    'Reply',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
