import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/profile_hunter_metrics.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/community_voice_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_content_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_signals_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_stats_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_hero_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_more_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_stats_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_tabs_section.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The single profile body for every space.
///
/// Sections are role-aware, not space-aware: hunter blocks appear for
/// anyone holding the hunter / admin / owner / dev role no matter which
/// space is active, and the shared sections (hero, tabs, More, Account)
/// appear for everyone. Nothing disappears when the user switches space.
class ProfileBody extends StatefulWidget {
  const ProfileBody({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthStore auth;
  final VoidCallback onSignOut;

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
      context.read<UpdatesStore>().fetchUpdatesOnce();
      levelsStore.fetchMyProgress();
      levelsStore.fetchAllLevels();
      if (widget.auth.hasHunterSpace) {
        context.read<ProjectsStore>().fetchProjectsOnce();
      }
    });
  }

  Future<void> _refresh() async {
    final futures = <Future<void>>[
      context.read<UserProfileStore>().refreshAll(),
      context.read<TipsStore>().loadOverview(force: true),
      context.read<TipsStore>().loadSentHistory(force: true, limit: 100),
      context.read<BadgesStore>().loadMyBadges(force: true),
      context.read<UpdatesStore>().refreshUpdates(),
      context.read<LevelsStore>().fetchMyProgress(),
      if (widget.auth.hasHunterSpace)
        context.read<ProjectsStore>().refreshProjects(),
    ];
    await Future.wait(futures);
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
    final accent = activeSpace.accent;

    final profileStore = context.watch<UserProfileStore>();
    final tipsStore = context.watch<TipsStore>();
    final badgesStore = context.watch<BadgesStore>();
    final levelsStore = context.watch<LevelsStore>();
    final earnedBadges = _earnedBadges(badgesStore);
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

    HunterProfileMetrics? hunterMetrics;
    if (isHunter) {
      hunterMetrics = HunterProfileMetrics.compute(
        projects: context.watch<ProjectsStore>().projects,
        updates: context.watch<UpdatesStore>().updates,
        userId: auth.userId ?? '',
        username: auth.username ?? auth.displayName ?? '',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: AppColors.bgSurface,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeroSection(
              displayName: displayName,
              avatarUrl: auth.avatarUrl,
              email: auth.email,
              bio: auth.bio,
              activeSpace: activeSpace,
              isHunter: isHunter,
              primaryBadge: badgesStore.displayBadge,
              badges: earnedBadges,
              currentLevel: levelsStore.myProgress?.currentLevel,
              onEditTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.editProfile),
            ),
            ProfileStatsSection(
              followingCount: profileStore.followingProfilesCount,
              tipsSent: tipsStore.profileTipsSentValue,
              badgeCount: earnedBadges.length,
              accent: accent,
            ),
            if (hunterMetrics != null) ...[
              HunterStatsSection(metrics: hunterMetrics),
              const SizedBox(height: AppSpace.lg),
              CommunityVoiceSection(metrics: hunterMetrics),
              const SizedBox(height: AppSpace.xl),
              HunterSignalsSection(updates: hunterMetrics.hunterUpdates),
            ],
            const SizedBox(height: AppSpace.lg),
            ProfileTabsSection(accent: accent),
            const SizedBox(height: AppSpace.lg),
            if (isHunter) ...[
              const HunterContentSection(),
              const SizedBox(height: AppSpace.md),
            ],
            ProfileMoreSection(auth: auth, onSignOut: widget.onSignOut),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
