import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/projects/update_bookmarks_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

part 'user_profile_body_hero.part.dart';
part 'user_profile_body_tabs.part.dart';
part 'user_profile_body_shared.part.dart';

/// Profile body shown when the user is in User space (no hunter role, or
/// hunter/admin who has not switched to Hunter space).
class UserProfileBody extends StatefulWidget {
  const UserProfileBody({
    super.key,
    required this.onSignOut,
    required this.auth,
  });

  final VoidCallback onSignOut;
  final AuthStore auth;

  @override
  State<UserProfileBody> createState() => _UserProfileBodyState();
}

class _UserProfileBodyState extends State<UserProfileBody> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = widget.auth.userId ?? '';
      final profileStore = context.read<UserProfileStore>();
      final tipsStore = context.read<TipsStore>();
      final badgesStore = context.read<BadgesStore>();
      final updatesStore = context.read<UpdatesStore>();
      final levelsStore = context.read<LevelsStore>();
      profileStore.fetchInitialOnce(userId: userId);
      profileStore.refreshFollowingProfiles();
      tipsStore.ensureUserScope(userId);
      tipsStore.loadOverview(force: true);
      tipsStore.loadSentHistory(force: true, limit: 100);
      badgesStore.loadMyBadges();
      updatesStore.fetchUpdatesOnce();
      levelsStore.fetchMyProgress();
      levelsStore.fetchAllLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileStore = context.watch<UserProfileStore>();
    final tipsStore = context.watch<TipsStore>();
    final badgesStore = context.watch<BadgesStore>();
    final levelsStore = context.watch<LevelsStore>();
    final followingCount = profileStore.followingProfilesCount;
    final tipsSent = tipsStore.profileTipsSentValue;
    final auth = widget.auth;
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final badgeById = <String, BadgeModel>{};
    for (final earned in badgesStore.myBadges) {
      final badge = earned.badge;
      if (badge.id.trim().isEmpty) continue;
      badgeById[badge.id] = badge;
    }
    final earnedBadges = badgeById.values.toList()
      ..sort((left, right) {
        final rarityDelta = right.rarity.index.compareTo(left.rarity.index);
        if (rarityDelta != 0) return rarityDelta;
        return left.sortOrder.compareTo(right.sortOrder);
      });

    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;
    final currentLevel = levelsStore.myProgress?.currentLevel;

    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () async {
        await Future.wait([
          context.read<UserProfileStore>().refreshAll(),
          context.read<TipsStore>().loadOverview(force: true),
          context.read<TipsStore>().loadSentHistory(force: true, limit: 100),
          context.read<BadgesStore>().loadMyBadges(force: true),
          context.read<UpdatesStore>().refreshUpdates(),
          context.read<LevelsStore>().fetchMyProgress(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserHero(
              displayName: displayName,
              avatarUrl: auth.avatarUrl,
              email: auth.email,
              primaryBadge: badgesStore.displayBadge,
              badges: earnedBadges,
              currentLevel: currentLevel,
              onEditTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.editProfile),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StatCard(
                      value: followingCount.toString(), label: 'Following'),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.borderSubtle.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  _StatCard(value: tipsSent, label: 'Tips Sent'),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.borderSubtle.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  _StatCard(
                    value: earnedBadges.length.toString(),
                    label: 'Badges',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileTabBar(
              tabs: const ['Activity', 'Following', 'Saved'],
              activeIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                switch (_tabIndex) {
                  0 => 'Your actions on Blocnet.',
                  1 => 'Projects you follow are listed here for quick access.',
                  _ => 'Items you bookmarked to revisit later.',
                },
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: switch (_tabIndex) {
                  0 => const _ActivityTab(),
                  1 => const _WatchlistTab(),
                  _ => const _BookmarksTab(),
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('More'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.emoji_events_outlined,
                    title: 'Badges',
                    subtitle: 'View and manage your earned badges',
                    showDivider: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.badges),
                  ),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.task_alt_outlined,
                    title: 'Quests',
                    subtitle: 'Complete quests to earn rewards',
                    showDivider: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.quests),
                  ),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Tip History',
                    subtitle: 'See all tips you sent to hunters',
                    showDivider: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.tipsHistory),
                  ),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.redeem_outlined,
                    title: 'Referral Code',
                    subtitle: 'View and manage your referral code',
                    showDivider: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.referralCode),
                  ),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Account preferences',
                    showDivider: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.support_agent_outlined,
                    title: 'Help & Support',
                    subtitle: 'Get help with account and app issues',
                    showDivider: false,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.helpSupport),
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  if (auth.isOwner || auth.isDev || auth.isAdmin)
                    _ProfileTile(
                      mode: viewMode,
                      icon: Icons.warning_amber_rounded,
                      title: 'System Alerts',
                      subtitle: 'Operational warnings and error events',
                      showDivider: true,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.systemAlerts),
                    ),
                  _ProfileTile(
                    mode: viewMode,
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    iconColor: AppColors.textMuted,
                    titleColor: AppColors.textSecondary,
                    showDivider: false,
                    onTap: widget.onSignOut,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
