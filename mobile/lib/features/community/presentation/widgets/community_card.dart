import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/community_action.dart';
import 'package:blocnet/features/community/presentation/widgets/community_post_share_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/community_report_submission_sheet.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/community/presentation/widgets/role_chip.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

  final CommunityPost post;
  final FeedViewMode mode;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmark;
  final Future<void> Function(CommunityContentModerationDecision decision)?
  onModerate;
  final bool canArchiveModeration;

  void _openAuthorProfile(BuildContext context) {
    final admin = post.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  Future<void> _openModerationActions(BuildContext context) async {
    if (onModerate == null) return;
    final decision = await showCommunityContentModerationSheet(
      context,
      targetLabel: 'post',
      canArchive: canArchiveModeration,
    );
    if (decision == null) return;
    await onModerate!(decision);
  }

  Future<void> _openReportSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CommunityReportSubmissionSheet(
          targetType: CommunityReportTargetType.communityPost,
          targetId: post.id,
          contentPreview: post.content.length > 100
              ? '${post.content.substring(0, 100)}...'
              : post.content,
        ),
      ),
    );
  }

  Future<void> _blockUser(BuildContext context) async {
    final authorId = post.admin?.id;
    final authorName = post.admin?.name ?? 'this user';
    if (authorId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'Block $authorName?',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You won\'t see their posts or comments anymore.',
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 13,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Block',
              style: AppTypography.custom(
                color: AppColors.error500,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final blocksStore = context.read<BlocksStore>();
    final success = await blocksStore.blockUser(authorId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blocked $authorName'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocksStore.error ?? 'Failed to block user'),
          backgroundColor: AppColors.error500,
        ),
      );
    }
  }

  Future<void> _showMoreOptions(BuildContext context) async {
    final auth = context.read<AuthStore>();
    final isModerator = auth.isCommunityModerator;
    final isOwnPost = post.admin?.id == auth.userId;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isModerator && onModerate != null)
                ListTile(
                  leading: Icon(Icons.shield_outlined, size: 20, color: AppColors.textSecondary),
                  title: Text(
                    'Moderate',
                    style: AppTypography.custom(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openModerationActions(context);
                  },
                ),
              if (!isOwnPost) ...[
                ListTile(
                  leading: Icon(Icons.flag_outlined, size: 20, color: AppColors.error500),
                  title: Text(
                    'Report Post',
                    style: AppTypography.custom(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.error500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openReportSheet(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.block, size: 20, color: AppColors.error500),
                  title: Text(
                    'Block User',
                    style: AppTypography.custom(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.error500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCardMode = mode == FeedViewMode.card;
    final admin = post.admin;
    final displayName =
        admin?.name.trim().isNotEmpty == true ? admin!.name : 'Blocnet User';
    final username = _formatUsername(
      admin?.username,
      fallbackName: displayName,
    );
    final role = admin?.displayRoleLabel;
    final roleColor = _resolveRoleColor(role);
    final content = post.content.trim();
    final auth = context.read<AuthStore>();
    final isOwnPost = post.admin?.id == auth.userId;

    final cardBody = InkWell(
      onTap: onTap,
      onLongPress: !isOwnPost ? () => _openReportSheet(context) : null,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(context),
                  behavior: HitTestBehavior.opaque,
                  child: AppAvatar(
                    radius: 22,
                    imageUrl: admin?.imageUrl,
                    fallback: _avatarFallback(displayName, roleColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => _openAuthorProfile(context),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: UserNameWithLevelIcon(
                                      name: displayName,
                                      currentLevel: admin?.currentLevel,
                                      levelBadgeSize: LevelBadgeSize.small,
                                      textStyle: AppTypography.custom(
                                        color: AppColors.textPrimary,
                                        size: 14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (role != null) ...[
                            const SizedBox(width: 8),
                            RoleChip(label: role, color: roleColor),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            getTimeStamp(post.createdAt),
                            style: AppTypography.custom(
                              color: AppColors.textFaint,
                              size: 11,
                              weight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showMoreOptions(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            username,
                            style: AppTypography.custom(
                              color: AppColors.textMuted,
                              size: 12,
                              weight: FontWeight.w400,
                            ),
                          ),
                          if (post.status != CommunityContentModerationStatus.active) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: post.status == CommunityContentModerationStatus.hidden
                                    ? AppColors.warning500.withValues(alpha: 0.15)
                                    : AppColors.error500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: post.status == CommunityContentModerationStatus.hidden
                                      ? AppColors.warning500.withValues(alpha: 0.4)
                                      : AppColors.error500.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                post.status == CommunityContentModerationStatus.hidden
                                    ? 'HIDDEN'
                                    : 'ARCHIVED',
                                style: AppTypography.custom(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: post.status == CommunityContentModerationStatus.hidden
                                      ? AppColors.warning500
                                      : AppColors.error500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      MentionText(
                        text: content,
                        style: AppTypography.custom(
                          color: AppColors.textSecondary,
                          size: 13,
                          height: 1.6,
                          weight: FontWeight.w400,
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommunityAction(
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  value: '${post.likesCount}',
                  color:
                      post.isLiked ? AppColors.primary400 : AppColors.textMuted,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onLike();
                  },
                ),
                CommunityAction(
                  icon: Icons.mode_comment_outlined,
                  value: '${post.commentsCount}',
                  color: post.isCommented
                      ? AppColors.primary400
                      : AppColors.textMuted,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCommentTap();
                  },
                ),
                CommunityAction(
                  icon: post.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  value: post.isBookmarked ? '1' : '',
                  color: post.isBookmarked
                      ? AppColors.primary400
                      : AppColors.textMuted,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onBookmark();
                  },
                ),
                CommunityAction(
                  icon: Icons.share_outlined,
                  value: '',
                  color: AppColors.teal400,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await showCommunityPostShareSheet(
                      context,
                      postId: post.id,
                      content: post.content,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!isCardMode) {
      return cardBody;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: cardBody,
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Text(
      firstChar,
      style: AppTypography.custom(
        color: color,
        size: 18,
        weight: FontWeight.w800,
      ),
    );
  }

  String _formatUsername(String? value, {required String fallbackName}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized.startsWith('@') ? normalized : '@$normalized';
    }

    final fallback = fallbackName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (fallback.isEmpty) return '@member';
    return '@$fallback';
  }

  Color _resolveRoleColor(String? role) {
    if (role == 'CORE TEAM') {
      return const Color(0xFF38BDF8);
    }
    if (role == 'MODERATOR') {
      return const Color(0xFFF59E0B);
    }
    if (role == 'HUNTER') {
      return const Color(0xFFC084FC);
    }
    if (role == 'ADMIN') {
      return AppColors.primary400;
    }
    return AppColors.primary400;
  }
}
