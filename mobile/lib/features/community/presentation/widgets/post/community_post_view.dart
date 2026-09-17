import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/community_post_share_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_author_line.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_content_menu.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_post_actions.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:flutter/material.dart';

/// A community post laid out as a Home feed post: the avatar beside name,
/// role pill and time; the body at full width below; then the actions.
///
/// Used by the feed card, the Saved list and the top of a discussion.
class CommunityPostView extends StatelessWidget {
  const CommunityPostView({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    this.onModerate,
    this.canArchiveModeration = false,
    this.maxBodyLines,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final Future<void> Function(CommunityContentModerationDecision decision)?
      onModerate;
  final bool canArchiveModeration;

  /// Clamp the body in lists; null shows it all.
  final int? maxBodyLines;

  void _openAuthor(BuildContext context) {
    final author = post.admin;
    if (author == null) return;
    PublicProfileScreen.showSheet(context, author);
  }

  Future<void> _moderate(BuildContext context) async {
    final decision = await showCommunityContentModerationSheet(
      context,
      targetLabel: 'post',
      canArchive: canArchiveModeration,
    );
    if (decision == null) return;
    await onModerate?.call(decision);
  }

  Future<void> _openMenu(BuildContext context) {
    return showCommunityContentMenu(
      context,
      targetType: CommunityReportTargetType.communityPost,
      targetId: post.id,
      content: post.content,
      author: post.admin,
      onModerate: onModerate == null ? null : () => _moderate(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMenu = communityMenuHasItems(
      context,
      author: post.admin,
      canModerate: onModerate != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CommunityAvatar(
              author: post.admin,
              onTap: () => _openAuthor(context),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: CommunityAuthorLine(
                author: post.admin,
                createdAt: post.createdAt,
                status: post.status,
                onTap: () => _openAuthor(context),
                trailing: hasMenu
                    ? CommunityMoreButton(onTap: () => _openMenu(context))
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        MentionText(
          text: post.content.trim(),
          maxLines: maxBodyLines,
          overflow: maxBodyLines == null ? null : TextOverflow.ellipsis,
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: AppText.bodySize,
            weight: FontWeight.w400,
            height: 1.5,
          ),
          onMentionTap: (username) =>
              MentionProfileNavigator.openFromUsername(context, username),
        ),
        const SizedBox(height: AppSpace.sm),
        CommunityPostActions(
          isLiked: post.isLiked,
          likesCount: post.likesCount,
          isCommented: post.isCommented,
          commentsCount: post.commentsCount,
          isSaved: post.isBookmarked,
          onLike: onLike,
          onComment: onComment,
          onSave: onSave,
          onShare: () => showCommunityPostShareSheet(
            context,
            postId: post.id,
            content: post.content,
          ),
        ),
      ],
    );
  }
}
