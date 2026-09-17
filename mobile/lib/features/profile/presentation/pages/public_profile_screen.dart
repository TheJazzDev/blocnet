import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/profile/data/models/public_profile_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_actions.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_identity.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_recent_activity.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_inline_state.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_header.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_reliability.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/utils/role_presentation.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
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

  void _retryPublicProfile() {
    setState(() => _isLoadingPublicProfile = true);
    _loadPublicProfile();
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
      AppSnackbar.showError(context, 'Could not update follow');
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
      AppSnackbar.showError(
        context,
        'Could not ${actionLabel.toLowerCase()} this user',
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
    final rawHandle = admin.username.trim();
    final handle = rawHandle.isEmpty
        ? null
        : (rawHandle.startsWith('@') ? rawHandle : '@$rawHandle');
    final displayRoleKey = publicProfile != null
        ? resolvePrimaryRoleKeyFromRoles(publicProfile.roles)
        : admin.primaryRoleKey;
    final isHunterTarget = publicProfile != null
        ? publicProfile.roles
            .map((role) => role.trim().toLowerCase())
            .contains('hunter')
        : admin.hasRole('hunter');
    final isOwnProfile = authStore.userId == admin.id;
    final canTipHunter = isHunterTarget &&
        authStore.userId != null &&
        !isOwnProfile &&
        admin.id.trim().isNotEmpty;

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: widget.asSheet ? AppRadius.sheet : BorderRadius.zero,
      ),
      child: SafeArea(
        top: !widget.asSheet,
        child: Column(
          children: [
            PublicProfileHeader(asSheet: widget.asSheet),
            Expanded(
              child: Consumer<UpdatesStore>(
                builder: (context, updatesStore, _) {
                  final posts = updatesStore.posts
                      .where((p) => p.admin?.id == admin.id)
                      .toList();
                  final stats = publicProfile?.stats;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PublicProfileIdentity(
                          admin: admin,
                          displayName: publicProfile?.displayName,
                          avatarUrl: publicProfile?.avatarUrl,
                          handle: handle,
                          roleKey: displayRoleKey,
                        ),
                        AppSpace.gapMd,
                        PublicProfileCounts(
                          followers: stats?.followersCount ?? admin.followers,
                          updates: stats?.updatesCreated ?? posts.length,
                          gems: stats?.projectsCreated ??
                              posts
                                  .map((post) => post.projectId)
                                  .toSet()
                                  .length,
                        ),
                        if (_isLoadingPublicProfile) ...[
                          AppSpace.gapMd,
                          LinearProgressIndicator(
                            minHeight: 2,
                            color: AppColors.primary400,
                            backgroundColor: AppColors.bgElevated,
                          ),
                        ] else if (publicProfile == null) ...[
                          AppSpace.gapMd,
                          AppRowGroup(
                            children: [
                              ProfileInlineState(
                                icon: Icons.cloud_off_rounded,
                                title: 'Could not load this profile',
                                actionLabel: 'Retry',
                                onAction: _retryPublicProfile,
                              ),
                            ],
                          ),
                        ],
                        AppSpace.gapLg,
                        if (!isOwnProfile)
                          Row(
                            children: [
                              Expanded(
                                child: PublicProfileFollowButton(
                                  isFollowing: _isFollowing,
                                  isSubmitting: _isSubmittingFollow,
                                  onPressed: _toggleFollow,
                                ),
                              ),
                              if (canTipHunter) ...[
                                AppSpace.wGapSm,
                                Expanded(
                                  child: PublicProfileTipButton(
                                    onPressed: () =>
                                        _openTipSheet(publicProfile),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (isHunterTarget) ...[
                          AppSpace.gapXl,
                          PublicProfileReliability(profileId: admin.id),
                        ],
                        AppSpace.gapXl,
                        PublicProfileRecentActivity(posts: posts),
                        if (!isOwnProfile) ...[
                          AppSpace.gapLg,
                          PublicProfileBlockButton(
                            isBlocked: _isBlocked,
                            isSubmitting: _isSubmittingBlock,
                            onPressed: _toggleBlock,
                          ),
                        ],
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
