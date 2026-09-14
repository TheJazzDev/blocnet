import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_action_row.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_emphasis.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_parts.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_tag_pill.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One feed card, laid out to the approved design.
///
/// Reference: `docs/artifacts/blocnet-home-feed-v2.html`. The order below is
/// the design's, element for element, and is the single place it is defined —
/// the screen previously had two hand-maintained copies of a card that had
/// drifted from the design in different ways.
///
/// ```
///   header   avatar · name + level + role / @handle · time · priority
///   project  gem pill
///   title
///   deadline (when the update carries one)
///   body
///   tags
///   edge     (when Edge has a verdict worth showing)
///   actions  like · comment · share | bookmark · Tip
/// ```
///
/// [dense] is the only thing that varies between the two feed view modes. It
/// changes padding and nothing else, because a card that rearranges itself per
/// mode is how the drift happened in the first place.
class FeedCardContent extends StatelessWidget {
  const FeedCardContent({
    super.key,
    required this.post,
    required this.emphasis,
    required this.authorLevel,
    required this.dense,
    required this.likeIcon,
    required this.isBookmarked,
    required this.isCommented,
    required this.likeCount,
    required this.commentCount,
    required this.bookmarkCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
    required this.onOpenAuthor,
    required this.onOpenProject,
    this.onTip,
    this.edgeSignals,
    this.edgeVerdict,
  });

  final Update post;
  final FeedCardEmphasis emphasis;
  final UserLevelModel? authorLevel;
  final bool dense;

  final Widget likeIcon;
  final bool isBookmarked;
  final bool isCommented;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;

  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onOpenAuthor;
  final VoidCallback onOpenProject;

  /// Null when there is nobody to tip. The pill is then absent, not disabled.
  final VoidCallback? onTip;

  final int? edgeSignals;
  final String? edgeVerdict;

  @override
  Widget build(BuildContext context) {
    final author = post.admin!;
    final project = post.project!;
    final title = post.title.trim();
    final body = post.description.trim().isEmpty
        ? post.content.trim()
        : post.description.trim();
    // A title that merely restates the body's opening reads as a stutter, so
    // the title wins and the body is left to the detail view.
    final showTitle =
        title.isNotEmpty && !body.toLowerCase().startsWith(title.toLowerCase());
    final gap = dense ? AppSpace.sm : AppSpace.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          author: author,
          level: authorLevel,
          post: post,
          onOpenAuthor: onOpenAuthor,
        ),
        SizedBox(height: gap),
        FeedProjectTag(project: project, onTap: onOpenProject),
        if (showTitle) ...[
          SizedBox(height: gap),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: emphasis.titleSize,
              weight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
        if (post.deadlineAt != null)
          FeedDeadlineLine(deadlineAt: post.deadlineAt!),
        if (body.isNotEmpty) ...[
          SizedBox(height: showTitle ? AppSpace.xs : gap),
          Text(
            body,
            maxLines: showTitle ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.55,
            ),
          ),
        ],
        if (post.secondaryTags.isNotEmpty) ...[
          SizedBox(height: gap),
          Wrap(
            spacing: AppSpace.xs + 2,
            runSpacing: AppSpace.xs + 2,
            children: post.secondaryTags
                .take(3)
                .map((tag) => FeedTagPill(label: tag.name))
                .toList(),
          ),
        ],
        if (edgeSignals != null && edgeVerdict != null) ...[
          SizedBox(height: gap),
          FeedEdgeTag(signals: edgeSignals!, verdict: edgeVerdict!),
        ],
        SizedBox(height: dense ? AppSpace.md : AppSpace.lg),
        FeedActionRow(
          likeIcon: likeIcon,
          onLikeTap: onLike,
          onCommentTap: onComment,
          onShareTap: onShare,
          onBookmarkTap: onBookmark,
          isBookmarked: isBookmarked,
          isCommented: isCommented,
          likeCount: likeCount,
          commentCount: commentCount,
          bookmarkCount: bookmarkCount,
          onTipTap: onTip,
        ),
      ],
    );
  }
}

/// Avatar, who wrote it, and how urgent it is — one row.
///
/// The avatar is plain. It used to carry a priority-tinted gradient ring, which
/// spent the urgency signal on a 42px circle at the moment the card gained a
/// full-height edge that says the same thing far more clearly.
class _Header extends StatelessWidget {
  const _Header({
    required this.author,
    required this.level,
    required this.post,
    required this.onOpenAuthor,
  });

  final dynamic author;
  final UserLevelModel? level;
  final Update post;
  final VoidCallback onOpenAuthor;

  @override
  Widget build(BuildContext context) {
    final roleLabel = author.displayRoleLabel as String?;
    final roleColor =
        roleLabel == 'HUNTER' ? AppColors.primary400 : const Color(0xFFA78BFA);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onOpenAuthor,
          behavior: HitTestBehavior.opaque,
          child: AppAvatar(
            radius: 20,
            imageUrl: author.imageUrl as String,
            fallback: Icon(
              Icons.person,
              size: AppIcon.md,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: GestureDetector(
            onTap: onOpenAuthor,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.xs + 2,
                  runSpacing: AppSpace.xs,
                  children: [
                    Text(
                      author.name as String,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.bodySize,
                        weight: FontWeight.w700,
                      ),
                    ),
                    // Name first, then the badge, then the role. The app had
                    // the badge leading, which put a number before the person.
                    if (level != null) FeedLevelBadge(level: level!),
                    if (roleLabel != null)
                      FeedRoleTag(label: roleLabel, color: roleColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_handle(author.username as String, author.id as String)}'
                  ' · ${getTimeStamp(post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.labelSize,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        FeedPriorityTag(priority: post.priority),
      ],
    );
  }
}

String _handle(String raw, String id) {
  final trimmed = raw.trim().replaceAll('@', '');
  if (trimmed.isEmpty) {
    return '@${id.substring(0, id.length >= 6 ? 6 : id.length)}';
  }
  return '@$trimmed';
}
