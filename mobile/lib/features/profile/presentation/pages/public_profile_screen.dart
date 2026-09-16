import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/profile/data/models/public_profile_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_actions.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_identity.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_recent_activity.dart';
import 'package:blocnet/features/profile/presentation/widgets/stat_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/trust_chips.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/utils/role_presentation.dart';
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
    final confirmed = await confirmPublicProfileBlock(
      context,
      isBlocked: _isBlocked,
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

  void _openTipSheet(PublicProfileModel? publicProfile) {
    final admin = widget.admin;
    TipHunterSheet.show(
      context,
      recipient: TipRecipient(
        userId: admin.id,
        username: admin.username,
        displayName: publicProfile?.displayName ?? admin.name,
        avatarUrl: publicProfile?.avatarUrl ?? admin.imageUrl,
        isHunterHint: true,
      ),
      contextType: 'public_profile',
      contextId: admin.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final authStore = context.watch<AuthStore>();
    final publicProfile = _publicProfile;
    final username = admin.username.trim().isNotEmpty
        ? admin.username
        : '@${admin.name.toLowerCase().replaceAll(' ', '_')}';
    final displayRoleKey = publicProfile != null
        ? resolvePrimaryRoleKeyFromRoles(publicProfile.roles)
        : admin.primaryRoleKey;
    final isHunterTarget = publicProfile != null
        ? publicProfile.roles
            .map((role) => role.trim().toLowerCase())
            .contains('hunter')
        : admin.hasRole('hunter');
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
                padding: const EdgeInsets.only(
                    top: AppSpace.md, bottom: AppSpace.sm),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.sm),
              child: Row(
                children: [
                  Text(
                    'Public Profile',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.subtitleSize,
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
                    child: Column(
                      children: [
                        PublicProfileIdentity(
                          admin: admin,
                          displayName: _publicProfile?.displayName,
                          username: username,
                          roleKey: displayRoleKey,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Row(
                          children: [
                            StatCard(
                                value: '$followersCount', label: 'Followers'),
                            const SizedBox(width: AppSpace.sm),
                            StatCard(value: '$postsCount', label: 'Posts'),
                            const SizedBox(width: AppSpace.sm),
                            StatCard(value: '$projectCount', label: 'Gems'),
                          ],
                        ),
                        if (_isLoadingPublicProfile) ...[
                          const SizedBox(height: AppSpace.md),
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
                          const SizedBox(height: AppSpace.lg),
                          TrustChips(trust: trust),
                        ],
                        const SizedBox(height: AppSpace.lg),
                        if (canTipHunter)
                          Row(
                            children: [
                              Expanded(
                                child: PublicProfileFollowButton(
                                  isFollowing: _isFollowing,
                                  isSubmitting: _isSubmittingFollow,
                                  onPressed: _toggleFollow,
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: PublicProfileTipButton(
                                  onPressed: () => _openTipSheet(publicProfile),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: PublicProfileFollowButton(
                              isFollowing: _isFollowing,
                              isSubmitting: _isSubmittingFollow,
                              onPressed: _toggleFollow,
                            ),
                          ),
                        if (!isOwnProfile) ...[
                          const SizedBox(height: AppSpace.md),
                          PublicProfileBlockButton(
                            isBlocked: _isBlocked,
                            isSubmitting: _isSubmittingBlock,
                            onPressed: _toggleBlock,
                          ),
                        ],
                        const SizedBox(height: AppSpace.lg),
                        PublicProfileRecentActivity(posts: posts),
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
}
