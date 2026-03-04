import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/profile/data/models/public_profile_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/activity_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/empty_activity_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_role_chip.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/profile/presentation/widgets/stat_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/trust_chips.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.admin,
    this.asSheet = false,
  });

  final Admin admin;
  final bool asSheet;

  static Future<void> showSheet(BuildContext context, Admin admin) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: PublicProfileScreen(admin: admin, asSheet: true),
      ),
    );
  }

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UsersApiRepository _usersRepository = UsersApiRepository();
  bool _isFollowing = false;
  bool _isSubmittingFollow = false;
  bool _isBlocked = false;
  bool _isSubmittingBlock = false;
  bool _isLoadingPublicProfile = true;
  PublicProfileModel? _publicProfile;

  @override
  void initState() {
    super.initState();
    _loadPublicProfile();
    _loadBlockStatus();
  }

  Future<void> _loadPublicProfile() async {
    try {
      final results = await Future.wait([
        _usersRepository.fetchPublicProfile(widget.admin.id),
        _usersRepository.fetchFollowedProfileIds(),
      ]);

      final profile = results[0] as PublicProfileModel?;
      final followedProfileIds = results[1] as Set<String>;
      if (!mounted) return;
      setState(() {
        _publicProfile = profile;
        _isFollowing = followedProfileIds.contains(widget.admin.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _publicProfile = null);
    } finally {
      if (mounted) {
        setState(() => _isLoadingPublicProfile = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isSubmittingFollow) return;
    final userProfileStore = context.read<UserProfileStore>();
    final wasFollowing = _isFollowing;
    setState(() => _isSubmittingFollow = true);
    userProfileStore.applyFollowingProfilesDelta(wasFollowing ? -1 : 1);
    setState(() => _isFollowing = !wasFollowing);

    try {
      if (wasFollowing) {
        await _usersRepository.unfollowProfile(widget.admin.id);
      } else {
        await _usersRepository.followProfile(widget.admin.id);
      }
      await userProfileStore.refreshFollowingProfiles();
    } catch (_) {
      userProfileStore.applyFollowingProfilesDelta(wasFollowing ? 1 : -1);
      if (!mounted) return;
      setState(() => _isFollowing = wasFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update follow status')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingFollow = false);
    }
  }

  Future<void> _loadBlockStatus() async {
    final authStore = context.read<AuthStore>();
    if (authStore.userId == null || authStore.userId == widget.admin.id) {
      return;
    }

    final blocksStore = context.read<BlocksStore>();
    final cachedBlocked = blocksStore.isUserBlocked(widget.admin.id);
    if (mounted && _isBlocked != cachedBlocked) {
      setState(() => _isBlocked = cachedBlocked);
    }

    try {
      final blocked = await blocksStore.isBlocked(widget.admin.id);
      if (!mounted) return;
      if (_isBlocked != blocked) {
        setState(() => _isBlocked = blocked);
      }
    } catch (_) {
      // Keep cached/default state and avoid blocking render.
    }
  }

  Future<void> _toggleBlock() async {
    if (_isSubmittingBlock) return;

    final actionLabel = _isBlocked ? 'Unblock' : 'Block';
    final description = _isBlocked
        ? 'You will start seeing this user in your feeds again.'
        : 'You will stop seeing this user in your feeds and comments.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          '$actionLabel user?',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          description,
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 13,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              actionLabel,
              style: AppTypography.custom(
                color: _isBlocked ? AppColors.primary400 : AppColors.error500,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmittingBlock = true);
    final blocksStore = context.read<BlocksStore>();

    final ok = _isBlocked
        ? await blocksStore.unblockUser(widget.admin.id)
        : await blocksStore.blockUser(widget.admin.id);

    if (!mounted) return;

    if (ok) {
      setState(() => _isBlocked = !_isBlocked);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocksStore.error ??
              'Failed to ${actionLabel.toLowerCase()} user'),
        ),
      );
    }

    setState(() => _isSubmittingBlock = false);
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final authStore = context.watch<AuthStore>();
    final publicProfile = _publicProfile;
    final username = admin.username.trim().isNotEmpty
        ? admin.username
        : '@${admin.name.toLowerCase().replaceAll(' ', '_')}';
    final displayRoleKeys = publicProfile != null
        ? _resolveRoleKeysFromRoles(publicProfile.roles)
        : _resolveRoleKeysFallback(admin);
    final isHunterTarget = publicProfile != null
        ? publicProfile.roles
            .map((role) => role.trim().toLowerCase())
            .contains('hunter')
        : displayRoleKeys.contains('hunter');
    final canTipHunter = isHunterTarget &&
        authStore.userId != null &&
        authStore.userId != admin.id &&
        admin.id.trim().isNotEmpty;
    final isOwnProfile = authStore.userId == admin.id;

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: widget.asSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.zero,
      ),
      child: SafeArea(
        top: !widget.asSheet,
        child: Column(
          children: [
            if (widget.asSheet)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Public Profile',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 17,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<UpdatesStore>(
                builder: (context, updatesStore, _) {
                  final posts = updatesStore.posts
                      .where((p) => p.admin?.id == admin.id)
                      .toList();
                  final stats = _publicProfile?.stats;
                  final trust = _publicProfile?.trust;
                  final followersCount =
                      stats?.followersCount ?? admin.followers;
                  final postsCount = stats?.updatesCreated ?? posts.length;
                  final projectCount = stats?.projectsCreated ??
                      posts.map((post) => post.projectId).toSet().length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Column(
                      children: [
                        AppAvatar(
                          radius: 42,
                          imageUrl: admin.imageUrl,
                          fallback: Text(
                            admin.name.isNotEmpty
                                ? admin.name[0].toUpperCase()
                                : 'U',
                            style: AppTypography.custom(
                              color: AppColors.primary400,
                              size: 24,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: UserNameWithLevelIcon(
                                name: (_publicProfile?.displayName
                                            ?.trim()
                                            .isNotEmpty ??
                                        false)
                                    ? _publicProfile!.displayName!.trim()
                                    : admin.name,
                                currentLevel: admin.currentLevel,
                                levelBadgeSize: LevelBadgeSize.small,
                                textStyle: AppTypography.custom(
                                  color: AppColors.textPrimary,
                                  size: 22,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (admin.primaryBadge != null) ...[
                              const SizedBox(width: 8),
                              BadgeIcon(
                                badge: admin.primaryBadge!,
                                size: BadgeSize.medium,
                                showTooltip: false,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username,
                          style: AppTypography.custom(
                            color: AppColors.textMuted,
                            size: 13,
                            weight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (displayRoleKeys.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: displayRoleKeys
                                .map(
                                  (roleKey) => ProfileRoleChip(
                                    label: _roleLabel(roleKey),
                                    textColor: _roleTextColor(roleKey),
                                    borderColor: _roleBorderColor(roleKey),
                                    backgroundColor:
                                        _roleBackgroundColor(roleKey),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            StatCard(
                                value: '$followersCount', label: 'Followers'),
                            const SizedBox(width: 8),
                            StatCard(value: '$postsCount', label: 'Posts'),
                            const SizedBox(width: 8),
                            StatCard(value: '$projectCount', label: 'Projects'),
                          ],
                        ),
                        if (_isLoadingPublicProfile) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.primary400,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                        if (trust != null) ...[
                          const SizedBox(height: 14),
                          TrustChips(trust: trust),
                        ],
                        const SizedBox(height: 14),
                        if (canTipHunter)
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: _isSubmittingFollow
                                        ? null
                                        : _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFollowing
                                          ? AppColors.bgElevated
                                          : AppColors.primary500,
                                      foregroundColor: _isFollowing
                                          ? AppColors.textPrimary
                                          : Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubmittingFollow
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: _isFollowing
                                                  ? AppColors.textPrimary
                                                  : Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _isFollowing
                                                ? 'Following'
                                                : 'Follow',
                                            style: AppTypography.custom(
                                              color: _isFollowing
                                                  ? AppColors.textPrimary
                                                  : Colors.black,
                                              size: 13,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      TipHunterSheet.show(
                                        context,
                                        recipient: TipRecipient(
                                          userId: admin.id,
                                          username: admin.username,
                                          displayName:
                                              publicProfile?.displayName ??
                                                  admin.name,
                                          avatarUrl: publicProfile?.avatarUrl ??
                                              admin.imageUrl,
                                          isHunterHint: true,
                                        ),
                                        contextType: 'public_profile',
                                        contextId: admin.id,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary500
                                          .withValues(alpha: 0.14),
                                      foregroundColor: AppColors.primary400,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppColors.primary500
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: AppColors.primary400,
                                      size: 17,
                                    ),
                                    label: Text(
                                      'Tip Hunter',
                                      style: AppTypography.custom(
                                        color: AppColors.primary400,
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmittingFollow ? null : _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? AppColors.bgElevated
                                    : AppColors.primary500,
                                foregroundColor: _isFollowing
                                    ? AppColors.textPrimary
                                    : Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmittingFollow
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: _isFollowing
                                            ? AppColors.textPrimary
                                            : Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: AppTypography.custom(
                                        color: _isFollowing
                                            ? AppColors.textPrimary
                                            : Colors.black,
                                        size: 13,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        if (!isOwnProfile) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isSubmittingBlock ? null : _toggleBlock,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isBlocked
                                      ? AppColors.primary400
                                          .withValues(alpha: 0.5)
                                      : AppColors.error500
                                          .withValues(alpha: 0.45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: _isBlocked
                                    ? AppColors.primary500
                                        .withValues(alpha: 0.08)
                                    : AppColors.error500
                                        .withValues(alpha: 0.08),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: _isSubmittingBlock
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _isBlocked
                                            ? AppColors.primary400
                                            : AppColors.error500,
                                      ),
                                    )
                                  : Icon(
                                      _isBlocked
                                          ? Icons.check_circle_outline
                                          : Icons.block_outlined,
                                      size: 16,
                                      color: _isBlocked
                                          ? AppColors.primary400
                                          : AppColors.error500,
                                    ),
                              label: Text(
                                _isBlocked ? 'User blocked' : 'Block user',
                                style: AppTypography.custom(
                                  color: _isBlocked
                                      ? AppColors.primary400
                                      : AppColors.error500,
                                  size: 12,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const SectionLabel('Recent Activity'),
                        const SizedBox(height: 8),
                        if (posts.isEmpty)
                          const EmptyActivityCard()
                        else
                          ...posts.take(4).map(
                                (post) => ActivityCard(
                                  title: post.title,
                                  subtitle: post.project?.name ?? 'Project',
                                  time: getTimeStamp(post.createdAt),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.asSheet) return content;
    return Scaffold(backgroundColor: AppColors.bgBase, body: content);
  }

  List<String> _resolveRoleKeysFallback(Admin admin) {
    if (admin.isAdminRole) return ['admin'];
    if (admin.isHunterRole) return ['hunter'];
    return const [];
  }

  List<String> _resolveRoleKeysFromRoles(List<String> roles) {
    final normalized = roles.map((role) => role.trim().toLowerCase()).toSet();
    final resolved = <String>[];

    if (normalized.contains('owner') || normalized.contains('admin')) {
      resolved.add('admin');
    }
    if (normalized.contains('hunter')) {
      resolved.add('hunter');
    }
    return resolved;
  }

  String _roleLabel(String roleKey) {
    switch (roleKey) {
      case 'admin':
        return 'ADMIN';
      case 'hunter':
        return 'HUNTER';
      default:
        return roleKey.toUpperCase();
    }
  }

  Color _roleTextColor(String roleKey) {
    switch (roleKey) {
      case 'hunter':
        return const Color(0xFFC084FC);
      case 'admin':
        return AppColors.primary400;
      default:
        return AppColors.textMuted;
    }
  }

  Color _roleBorderColor(String roleKey) {
    return _roleTextColor(roleKey).withValues(alpha: 0.55);
  }

  Color _roleBackgroundColor(String roleKey) {
    return _roleTextColor(roleKey).withValues(alpha: 0.15);
  }
}
