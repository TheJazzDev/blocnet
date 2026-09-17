import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/profile/presentation/navigation/profile_gems_link.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_hub_link_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_hero_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_more_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_stats_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_tabs_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_activity_tab.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The single profile body for every space.
///
/// Sections are role-aware, not space-aware: the hunter block appears for
/// anyone holding the hunter / admin / owner / dev role no matter which
/// space is active; hero, stats, tabs, More and Account appear for everyone.
/// Hunter stats, signals and content shortcuts live on the Hub, not here.
class ProfileBody extends StatefulWidget {
  const ProfileBody({
    super.key,
    required this.auth,
    required this.onSignOut,
    this.onOpenActivity,
  });

  final AuthStore auth;
  final VoidCallback onSignOut;

  /// Overrides where Activity rows go; tests use it.
  final ActivityTargetOpener? onOpenActivity;

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = widget.auth.userId ?? '';
      final profileStore = context.read<UserProfileStore>();
      final tipsStore = context.read<TipsStore>();
      final levelsStore = context.read<LevelsStore>();
      profileStore.fetchInitialOnce(userId: userId);
      profileStore.refreshFollowingProfiles();
      tipsStore.ensureUserScope(userId);
      tipsStore.loadOverview(force: true);
      tipsStore.loadSentHistory(force: true, limit: 100);
      context.read<BadgesStore>().loadMyBadges();
      levelsStore.fetchMyProgress();
      levelsStore.fetchAllLevels();
    });
  }

  Future<void> _refresh() async {
    final hunterBoard = widget.auth.hasHunterSpace
        ? context.read<HunterBoardStore?>()
        : null;
    await Future.wait(<Future<void>>[
      context.read<UserProfileStore>().refreshAll(forceRefresh: true),
      context.read<TipsStore>().loadOverview(force: true),
      context.read<TipsStore>().loadSentHistory(force: true, limit: 100),
      context.read<BadgesStore>().loadMyBadges(force: true),
      context.read<LevelsStore>().fetchMyProgress(),
      if (hunterBoard != null) hunterBoard.loadBoard(),
    ]);
  }

  List<BadgeModel> _earnedBadges(BadgesStore badgesStore) {
    final byId = <String, BadgeModel>{};
    for (final earned in badgesStore.myBadges) {
      final badge = earned.badge;
      if (badge.id.trim().isEmpty) continue;
      byId[badge.id] = badge;
    }
    return byId.values.toList()
      ..sort((left, right) {
        final rarityDelta = right.rarity.index.compareTo(left.rarity.index);
        if (rarityDelta != 0) return rarityDelta;
        return left.sortOrder.compareTo(right.sortOrder);
      });
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final isHunter = auth.hasHunterSpace;
    final activeSpace = SpaceMeta.currentFor(auth);

    final profileStore = context.watch<UserProfileStore>();
    final tipsStore = context.watch<TipsStore>();
    final badgesStore = context.watch<BadgesStore>();
    final levelsStore = context.watch<LevelsStore>();
    final earnedBadges = _earnedBadges(badgesStore);
    final navigator = Navigator.of(context);

    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: AppColors.bgSurface,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeroSection(
              displayName: _displayName(auth),
              avatarUrl: auth.avatarUrl,
              handle: _handle(auth),
              bio: auth.bio,
              activeSpace: activeSpace,
              isHunter: isHunter,
              primaryBadge: badgesStore.displayBadge,
              badges: earnedBadges,
              currentLevel: levelsStore.myProgress?.currentLevel,
              onEditTap: () => navigator.pushNamed(AppRoutes.editProfile),
            ),
            ProfileStatsSection(
              gemsFollowed: profileStore.hasLoadedWatchlist
                  ? profileStore.watchlist.length
                  : null,
              peopleFollowed: profileStore.followingProfilesCount,
              tipsSent: _tipsSentCount(tipsStore),
              badgeCount: earnedBadges.length,
              onGemsTap: () => openFollowedGems(context),
              onTipsTap: () => navigator.pushNamed(AppRoutes.tipsHistory),
              onBadgesTap: () => navigator.pushNamed(AppRoutes.badges),
            ),
            if (isHunter) ...[
              AppSpace.gapXl,
              HunterHubLinkSection(inHunterSpace: auth.isInHunterSpace),
            ],
            AppSpace.gapXl,
            ProfileTabsSection(
              accent: activeSpace.accent,
              onOpenActivity: widget.onOpenActivity,
            ),
            AppSpace.gapXl,
            ProfileMoreSection(auth: auth, onSignOut: widget.onSignOut),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Tips sent, counted across currencies. The old tile mixed an amount in
  /// one currency with a count, depending on what had loaded.
  static int _tipsSentCount(TipsStore tips) {
    final overview = tips.overview;
    if (overview == null) return tips.sentHistoryTotal;
    final byCurrency = overview.sentSummaryByCurrency;
    if (byCurrency.isNotEmpty) {
      return byCurrency.fold(0, (sum, row) => sum + row.transactionCount);
    }
    return overview.sentSummary?.transactionCount ?? tips.sentHistoryTotal;
  }

  static String _displayName(AuthStore auth) {
    final name = auth.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return (auth.email ?? '').split('@').first;
  }

  static String? _handle(AuthStore auth) {
    final username = auth.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }
    return auth.email;
  }
}
