import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/badges_store.dart';
import 'package:blocnet/services/tips_store.dart';
import 'package:blocnet/services/update_bookmarks_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/user_profile_store.dart';
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
      profileStore.fetchInitialOnce(userId: userId);
      profileStore.refreshFollowingProfiles();
      tipsStore.ensureUserScope(userId);
      tipsStore.loadOverview(force: true);
      tipsStore.loadSentHistory(force: true, limit: 100);
      badgesStore.loadMyBadges();
      updatesStore.fetchUpdatesOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileStore = context.watch<UserProfileStore>();
    final tipsStore = context.watch<TipsStore>();
    final badgesStore = context.watch<BadgesStore>();
    final followingCount = profileStore.followingProfilesCount;
    final tipsSent = tipsStore.profileTipsSentValue;
    final auth = widget.auth;

    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

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
              onEditTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.editProfile),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _StatCard(
                      value: followingCount.toString(), label: 'Following'),
                  const SizedBox(width: 8),
                  _StatCard(value: tipsSent, label: 'Tips Sent'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileTabBar(
              tabs: const ['History', 'Watchlist', 'Bookmarks'],
              activeIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: switch (_tabIndex) {
                  0 => const _HistoryTab(),
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
                    icon: Icons.emoji_events_outlined,
                    title: 'Badges',
                    subtitle: 'View and manage your earned badges',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.badges),
                  ),
                  _ProfileTile(
                    icon: Icons.task_alt_outlined,
                    title: 'Quests',
                    subtitle: 'Complete quests to earn rewards',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.quests),
                  ),
                  _ProfileTile(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Tip History',
                    subtitle: 'See all tips you sent to hunters',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.tipsHistory),
                  ),
                  _ProfileTile(
                    icon: Icons.redeem_outlined,
                    title: 'Referral Code',
                    subtitle: 'View and manage your referral code',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.referralCode),
                  ),
                  _ProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Account preferences',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  _ProfileTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Help & Support',
                    subtitle: 'Get help with account and app issues',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.helpSupport),
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    iconColor: AppColors.textMuted,
                    titleColor: AppColors.textSecondary,
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
