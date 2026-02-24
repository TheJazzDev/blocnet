import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/profile/data/models/public_profile_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/user_profile_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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
  bool _isLoadingPublicProfile = true;
  PublicProfileModel? _publicProfile;

  @override
  void initState() {
    super.initState();
    _loadPublicProfile();
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
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: AppColors.bgElevated,
                          backgroundImage: admin.imageUrl.isNotEmpty
                              ? NetworkImage(admin.imageUrl)
                              : null,
                          child: admin.imageUrl.isEmpty
                              ? Text(
                                  admin.name.isNotEmpty
                                      ? admin.name[0].toUpperCase()
                                      : 'U',
                                  style: AppTypography.custom(
                                    color: AppColors.primary400,
                                    size: 24,
                                    weight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                (_publicProfile?.displayName
                                            ?.trim()
                                            .isNotEmpty ??
                                        false)
                                    ? _publicProfile!.displayName!.trim()
                                    : admin.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.custom(
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
                                  (roleKey) => _ProfileRoleChip(
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
                            _StatCard(
                                value: '$followersCount', label: 'Followers'),
                            const SizedBox(width: 8),
                            _StatCard(value: '$postsCount', label: 'Posts'),
                            const SizedBox(width: 8),
                            _StatCard(
                                value: '$projectCount', label: 'Projects'),
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
                          _TrustChips(trust: trust),
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
                        const SizedBox(height: 16),
                        const _SectionLabel('Recent Activity'),
                        const SizedBox(height: 8),
                        if (posts.isEmpty)
                          _EmptyActivityCard()
                        else
                          ...posts.take(4).map(
                                (post) => _ActivityCard(
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

class _ProfileRoleChip extends StatelessWidget {
  const _ProfileRoleChip({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: textColor,
          size: 10,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrustChips extends StatelessWidget {
  const _TrustChips({required this.trust});

  final PublicProfileTrust trust;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _TrustChip(
            label: 'Updates (7d)',
            value: '${trust.updatesLast7d}',
          ),
          _TrustChip(
            label: 'Updates (30d)',
            value: '${trust.updatesLast30d}',
          ),
          _TrustChip(
            label: 'High-Urgency Share',
            value: '${trust.highUrgencyShare30d.toStringAsFixed(0)}%',
          ),
          _TrustChip(
            label: 'Median Posting Interval',
            value: trust.medianHoursBetweenUpdates == null
                ? 'N/A'
                : '${trust.medianHoursBetweenUpdates!.toStringAsFixed(1)}h',
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTypography.custom(
            size: 10,
            weight: FontWeight.w400,
            color: AppColors.textFaint,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: AppColors.textFaint),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: AppColors.textFaint,
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 17,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No public posts available yet.',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: 12,
          weight: FontWeight.w400,
        ),
      ),
    );
  }
}
