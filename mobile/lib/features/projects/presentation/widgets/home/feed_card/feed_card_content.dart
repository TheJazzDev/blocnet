import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_action_row.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_emphasis.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_header.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_parts.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_tag_pill.dart';
import 'package:flutter/material.dart';

/// One feed card, in the app's original layout: the avatar in a left column,
/// everything else stacked beside it.
///
/// ```
///   avatar | level · name · role · time
///          | @handle
///          | in gem-name ............. PRIORITY
///          | tags
///          | title
///          | deadline (when the update carries one)
///          | body
///          | edge     (when Edge has a verdict worth showing)
///          | like · comment · bookmark · share · Tip
/// ```
///
/// [dense] is the only thing that varies between the two feed view modes, and
/// it changes spacing only.
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedCardAvatar(author: author, onTap: onOpenAuthor),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedCardAuthorLine(
                author: author,
                level: authorLevel,
                createdAt: post.createdAt,
                onTap: onOpenAuthor,
              ),
              const SizedBox(height: AppSpace.sm),
              FeedProjectTag(
                project: project,
                priority: post.priority,
                onTap: onOpenProject,
              ),
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
              if (edgeSignals != null && edgeVerdict != null) ...[
                SizedBox(height: gap),
                FeedEdgeTag(signals: edgeSignals!, verdict: edgeVerdict!),
              ],
              SizedBox(height: gap),
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
          ),
        ),
      ],
    );
  }
}
