import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_action.dart';
import 'package:blocnet/features/community/presentation/widgets/role_chip.dart';
import 'package:blocnet/features/mentions/presentation/utils/mention_profile_navigator.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onCommentTap,
    required this.onBookmark,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmark;

  void _openAuthorProfile(BuildContext context) {
    final admin = post.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  Future<void> _openShareSheet(BuildContext context) async {
    final webLink = 'https://blocnet.app/community/${post.id}';
    final deepLink = 'blocnet://community/posts/${post.id}';
    final shareText = '${post.content.trim()}\n$webLink';

    Future<void> copyLink() async {
      await Clipboard.setData(ClipboardData(text: webLink));
      if (!context.mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Post link copied');
    }

    Future<void> openExternal(Uri uri, String platformName) async {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (!context.mounted) return;
        AppSnackbar.showError(
          context,
          'Could not open $platformName. Link copied instead.',
        );
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share post',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.content.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _ShareOptionTile(
                  icon: Icons.copy_all_rounded,
                  title: 'Copy link',
                  subtitle: webLink,
                  onTap: copyLink,
                ),
                _ShareOptionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Share to WhatsApp',
                  subtitle: 'Open WhatsApp with post link',
                  onTap: () => openExternal(
                    Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
                    ),
                    'WhatsApp',
                  ),
                ),
                _ShareOptionTile(
                  icon: Icons.send_outlined,
                  title: 'Share to Telegram',
                  subtitle: 'Open Telegram with post link',
                  onTap: () => openExternal(
                    Uri.parse(
                      'https://t.me/share/url?url=${Uri.encodeComponent(webLink)}&text=${Uri.encodeComponent(post.content.trim())}',
                    ),
                    'Telegram',
                  ),
                ),
                _ShareOptionTile(
                  icon: Icons.link_rounded,
                  title: 'Copy deep link',
                  subtitle: deepLink,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: deepLink));
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    AppSnackbar.showSuccess(context, 'Deep link copied');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      post.isLiked ? AppColors.warning500 : AppColors.textMuted,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onLike();
                  },
                ),
                CommunityAction(
                  icon: Icons.mode_comment_outlined,
                  value: '${post.commentsCount}',
                  color: AppColors.textMuted,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCommentTap();
                  },
                ),
                CommunityAction(
                  icon: Icons.share_outlined,
                  value: '',
                  color: AppColors.teal400,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await _openShareSheet(context);
                  },
                ),
                CommunityAction(
                  icon: post.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  value: '',
                  color: post.isBookmarked
                      ? AppColors.primary400
                      : AppColors.textMuted,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onBookmark();
                  },
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

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
      title: Text(
        title,
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: 13,
          weight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.custom(
          color: AppColors.textFaint,
          size: 11,
          weight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
