import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/community/presentation/widgets/role_chip.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommunityDiscussionPostDetailsCard extends StatelessWidget {
  const CommunityDiscussionPostDetailsCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onBookmark,
    this.onModerate,
    this.canArchiveModeration = false,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
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

  @override
  Widget build(BuildContext context) {
    final admin = post.admin;
    final adminName =
        admin?.name.trim().isNotEmpty == true ? admin!.name : 'Blocnet User';
    final username = _formatUsername(
      admin?.username,
      fallbackName: adminName,
    );
    final roleLabel = admin?.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                  radius: 20,
                  imageUrl: post.admin?.imageUrl,
                  fallback: Text(
                    adminName[0].toUpperCase(),
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openAuthorProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Flexible(
                            child: UserNameWithLevelIcon(
                              name: adminName,
                              currentLevel: admin?.currentLevel,
                              levelBadgeSize: LevelBadgeSize.small,
                              textStyle: AppTypography.custom(
                                color: AppColors.textPrimary,
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (admin?.primaryBadge != null) ...[
                            const SizedBox(width: 6),
                            BadgeIcon(
                              badge: admin!.primaryBadge!,
                              size: BadgeSize.small,
                              showTooltip: false,
                            ),
                          ],
                          if (roleLabel != null) ...[
                            const SizedBox(width: 6),
                            RoleChip(label: roleLabel, color: roleColor),
                          ],
                          if (onModerate != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _openModerationActions(context),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 12,
                        weight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      getTimeStamp(post.createdAt),
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MentionText(
            text: post.content,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 14,
              weight: FontWeight.w400,
              height: 1.55,
            ),
            onMentionTap: (mentionUsername) async {
              await MentionProfileNavigator.openFromUsername(
                context,
                mentionUsername,
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DiscussionAction(
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
              _DiscussionAction(
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
              _DiscussionAction(
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
              _DiscussionAction(
                icon: Icons.share_outlined,
                value: '',
                color: AppColors.teal400,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onShareTap();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        ],
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
}

class _DiscussionAction extends StatelessWidget {
  const _DiscussionAction({
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                value,
                style: AppTypography.custom(
                  color: color,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
