import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_post_view.dart';
import 'package:flutter/material.dart';

/// The post at the top of its discussion: the full text on a flat card.
class CommunityDiscussionPostDetailsCard extends StatelessWidget {
  const CommunityDiscussionPostDetailsCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onCommentTap,
    required this.onBookmark,
    this.onModerate,
    this.canArchiveModeration = false,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmark;
  final Future<void> Function(CommunityContentModerationDecision decision)?
      onModerate;
  final bool canArchiveModeration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpace.card,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: CommunityPostView(
        post: post,
        onLike: onLike,
        onComment: onCommentTap,
        onSave: onBookmark,
        onModerate: onModerate,
        canArchiveModeration: canArchiveModeration,
      ),
    );
  }
}
