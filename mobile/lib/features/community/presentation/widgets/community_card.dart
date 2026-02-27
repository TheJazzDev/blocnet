import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_action.dart';
import 'package:blocnet/features/community/presentation/widgets/role_chip.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onBookmark,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  void _openAuthorProfile(BuildContext context) {
    final admin = post.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  @override
  Widget build(BuildContext context) {
    final admin = post.admin;
    final displayName =
        admin?.name.trim().isNotEmpty == true ? admin!.name : 'Blocnet User';
    final username = _formatUsername(
      admin?.username,
      fallbackName: displayName,
    );
    final role = _resolveRoleLabel(admin);
    final roleColor = _resolveRoleColor(role);
    final badge = admin?.primaryBadge;
    final content = post.content.trim();

    return InkWell(
      onTap: onTap,
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
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.custom(
                                        color: AppColors.textPrimary,
                                        size: 14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 6),
                                    BadgeIcon(
                                      badge: badge,
                                      size: BadgeSize.small,
                                      showTooltip: false,
                                    ),
                                  ],
                                  if (role != null) ...[
                                    const SizedBox(width: 6),
                                    RoleChip(label: role, color: roleColor),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                        text: content,
                        style: AppTypography.custom(
                          color: AppColors.textSecondary,
                          size: 13,
                          height: 1.6,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CommunityAction(
                    icon: post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    value: '${post.likesCount}',
                    color: post.isLiked
                        ? AppColors.warning500
                        : AppColors.textMuted,
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: CommunityAction(
                    icon: Icons.mode_comment_outlined,
                    value: '${post.commentsCount}',
                    color: AppColors.textMuted,
                    onTap: onTap,
                  ),
                ),
                Expanded(
                  child: CommunityAction(
                    icon: post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    value: '',
                    color: post.isBookmarked
                        ? AppColors.primary400
                        : AppColors.textMuted,
                    onTap: onBookmark,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  String? _resolveRoleLabel(Admin? admin) {
    final roles = (admin?.roles ?? const <String>[])
        .map((role) => role.toLowerCase())
        .toSet();
    if (roles.contains('owner') || roles.contains('admin')) return 'ADMIN';
    if (roles.contains('hunter')) return 'HUNTER';
    return null;
  }

  Color _resolveRoleColor(String? role) {
    if (role == 'HUNTER') {
      return const Color(0xFFC084FC);
    }
    if (role == 'ADMIN') {
      return AppColors.primary400;
    }
    return AppColors.primary400;
  }
}
