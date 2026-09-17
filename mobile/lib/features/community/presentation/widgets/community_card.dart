import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/post/community_post_view.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:flutter/material.dart';

/// A community post in a list. Card mode is a flat surface with a hairline
/// border; list mode is a plain row between dividers, as on the Home feed.
class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.post,
    required this.mode,
    required this.onTap,
    required this.onLike,
    required this.onCommentTap,
    required this.onBookmark,
    this.onModerate,
    this.canArchiveModeration = false,
  });

  /// Lines of body shown in a list before it is cut with an ellipsis; the
  /// discussion shows the rest.
  static const int bodyLines = 8;

  final CommunityPost post;
  final FeedViewMode mode;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmark;
  final Future<void> Function(CommunityContentModerationDecision decision)?
      onModerate;
  final bool canArchiveModeration;

  @override
  Widget build(BuildContext context) {
    final isCard = mode == FeedViewMode.card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: isCard
            ? AppSpace.card
            : const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: isCard
            ? const BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.lg,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.borderSubtle),
                ),
              )
            : null,
        child: CommunityPostView(
          post: post,
          maxBodyLines: bodyLines,
          onLike: onLike,
          onComment: onCommentTap,
          onSave: onBookmark,
          onModerate: onModerate,
          canArchiveModeration: canArchiveModeration,
        ),
      ),
    );
  }
}
