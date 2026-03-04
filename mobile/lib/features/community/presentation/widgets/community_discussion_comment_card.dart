import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
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
  });

  final CommunityPostComment comment;

  void _openAuthorProfile(BuildContext context) {
    final admin = comment.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
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
              ],
            ),
          ),
        ],
      ),
    );
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
