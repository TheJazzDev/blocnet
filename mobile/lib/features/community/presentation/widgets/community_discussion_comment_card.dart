import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/community/presentation/widgets/role_chip.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

class CommunityDiscussionEmpty extends StatelessWidget {
  const CommunityDiscussionEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No comments yet. Start the discussion.',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: 13,
          weight: FontWeight.w400,
        ),
      ),
    );
  }
}

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

  void _openAuthorProfile(BuildContext context) {
    final admin = comment.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  Future<void> _openModerationActions(BuildContext context) async {
    if (onModerate == null) return;
    final decision = await showCommunityContentModerationSheet(
      context,
      targetLabel: 'comment',
      canArchive: canArchiveModeration,
    );
    if (decision == null) return;
    await onModerate!(decision);
  }

  @override
  Widget build(BuildContext context) {
    final admin = comment.admin;
    final name = admin?.name.trim().isNotEmpty == true ? admin!.name : 'User';
    final username = _formatUsername(
      admin?.username,
      fallbackName: name,
    );
    final roleLabel = admin?.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openAuthorProfile(context),
          behavior: HitTestBehavior.opaque,
          child: AppAvatar(
            radius: 18,
            imageUrl: comment.admin?.imageUrl,
            fallback: _avatarFallback(name),
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
                              name: name,
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
                  if (roleLabel != null) ...[
                    const SizedBox(width: 8),
                    RoleChip(label: roleLabel, color: roleColor),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    getTimeStamp(comment.createdAt),
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 11,
                      weight: FontWeight.w500,
                    ),
                  ),
                  if (onModerate != null) ...[
                    const SizedBox(width: 4),
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
              const SizedBox(height: 2),
              Text(
                username,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              if (!isNestedReply && comment.replyToData != null) ...[
                GestureDetector(
                  onTap: () {
                    // TODO: Scroll to original comment
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bgBase,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.borderSubtle.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to ',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: 11,
                                weight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              '@${_formatReplyUsername(comment.replyToData!)}',
                              style: AppTypography.custom(
                                color: AppColors.primary400,
                                size: 11,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _truncateContent(comment.replyToData!.content, 50),
                          style: AppTypography.custom(
                            color: AppColors.textFaint,
                            size: 11,
                            weight: FontWeight.w400,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              MentionText(
                text: comment.content,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w400,
                  height: 1.6,
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
                children: [
                  if (onLike != null) ...[
                    GestureDetector(
                      onTap: onLike,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border,
                            size: 14,
                            color: comment.isLiked
                                ? AppColors.primary400
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likesCount.toString(),
                            style: AppTypography.custom(
                              color: comment.isLiked
                                  ? AppColors.primary400
                                  : AppColors.textMuted,
                              size: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (onReply != null)
                    GestureDetector(
                      onTap: onReply,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Reply',
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: isNestedReply ? 20 : 0,
      ),
      child: isNestedReply
          ? Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.borderSubtle.withValues(alpha: 0.75),
                    width: 2,
                  ),
                ),
              ),
              child: content,
            )
          : content,
    );
  }

  String _formatReplyUsername(ReplyToData data) {
    final username = data.username?.trim() ?? '';
    if (username.isNotEmpty) {
      return username.startsWith('@') ? username.substring(1) : username;
    }
    final displayName = data.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    }
    return data.id.substring(0, 6);
  }

  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  Widget _avatarFallback(String name) {
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Text(
      firstChar,
      style: AppTypography.custom(
        color: AppColors.primary400,
        size: 15,
        weight: FontWeight.w700,
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
