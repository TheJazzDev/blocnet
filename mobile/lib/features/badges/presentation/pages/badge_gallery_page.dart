import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/gallery/badge_details_sheet.dart';
import 'package:blocnet/features/badges/presentation/widgets/gallery/badge_progress_tab.dart';
import 'package:blocnet/features/badges/presentation/widgets/gallery/badge_tile.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BadgeGalleryPage extends StatefulWidget {
  const BadgeGalleryPage({super.key});

  @override
  State<BadgeGalleryPage> createState() => _BadgeGalleryPageState();
}

class _BadgeGalleryPageState extends State<BadgeGalleryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<BadgesStore>();
      store.loadAllBadges();
      store.loadMyBadges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openBadge(BadgeModel badge, bool isEarned) {
    showBadgeDetailsSheet(context, badge: badge, isEarned: isEarned);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Badges',
            backButton: true,
            showSearch: false,
            showFilter: false,
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary400,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle:
                AppText.label(AppColors.primary400, weight: AppText.bold),
            unselectedLabelStyle: AppText.label(AppColors.textMuted),
            indicatorColor: AppColors.primary400,
            dividerColor: AppColors.borderSubtle,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Mine'),
              Tab(text: 'Progress'),
            ],
          ),
          Expanded(
            child: Consumer<BadgesStore>(
              builder: (context, store, _) {
                final nothingLoaded =
                    store.allBadges.isEmpty && store.myBadges.isEmpty;
                if (nothingLoaded &&
                    (store.isLoadingAll || store.isLoadingMy)) {
                  return const SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: SkeletonList(
                      items: 6,
                      itemHeight: 84,
                      padding: AppSpace.allLg,
                    ),
                  );
                }
                // Only a failed load with nothing to show takes the whole
                // screen; a failed "set primary" must not hide the gallery.
                if (nothingLoaded && store.lastError != null) {
                  return Center(
                    child: AppEmptyState.error(
                      title: 'Could not load badges',
                      message: progressErrorText(
                        store.lastError,
                        fallback: 'Check your connection and try again.',
                      ),
                      onAction: store.refresh,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: store.refresh,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _allTab(store),
                      _mineTab(store),
                      BadgeProgressTab(store: store),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _allTab(BadgesStore store) {
    final badges = store.allBadges;
    if (badges.isEmpty) {
      return const _ScrollableEmpty(
        icon: Icons.emoji_events_outlined,
        title: 'No badges yet',
      );
    }
    return _BadgeGrid(
      itemCount: badges.length,
      itemBuilder: (index) {
        final badge = badges[index];
        final isEarned = store.hasBadge(badge.id);
        return BadgeTile(
          badge: badge,
          isEarned: isEarned,
          isPrimary: store.primaryBadge?.id == badge.id,
          onTap: () => _openBadge(badge, isEarned),
        );
      },
    );
  }

  Widget _mineTab(BadgesStore store) {
    final mine = store.myBadges;
    if (mine.isEmpty) {
      return const _ScrollableEmpty(
        icon: Icons.emoji_events_outlined,
        title: 'No badges earned yet',
        message: 'Quests and daily activity earn badges.',
      );
    }
    return _BadgeGrid(
      itemCount: mine.length,
      itemBuilder: (index) {
        final userBadge = mine[index];
        return BadgeTile(
          badge: userBadge.badge,
          isEarned: true,
          isPrimary: store.primaryBadge?.id == userBadge.badgeId,
          earnedAt: userBadge.earnedAt,
          onTap: () => _openBadge(userBadge.badge, true),
        );
      },
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpace.allLg,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: kBadgeTileExtent,
        crossAxisSpacing: AppSpace.md,
        mainAxisSpacing: AppSpace.md,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

/// An empty state that still lets pull-to-refresh work.
class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AppEmptyState(icon: icon, title: title, message: message),
      ],
    );
  }
}
