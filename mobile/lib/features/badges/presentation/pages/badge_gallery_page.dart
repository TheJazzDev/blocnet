import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BadgeGalleryPage extends StatefulWidget {
  const BadgeGalleryPage({super.key});

  @override
  State<BadgeGalleryPage> createState() => _BadgeGalleryPageState();
}

class _BadgeGalleryPageState extends State<BadgeGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BadgeCategory? _selectedCategory;
  BadgeRarity? _selectedRarity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBadges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    final store = context.read<BadgesStore>();
    await Future.wait([
      store.loadAllBadges(),
      store.loadMyBadges(),
    ]);
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
          Container(
            color: AppColors.bgBase,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary400,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary400,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All Badges'),
                Tab(text: 'My Badges'),
                Tab(text: 'Progress'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BadgesStore>(
              builder: (context, store, child) {
                if (store.isLoadingAll || store.isLoadingMy) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (store.lastError != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          store.lastError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBadges,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => store.refresh(),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllBadgesTab(store),
                      _buildMyBadgesTab(store),
                      _buildProgressTab(store),
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

  Widget _buildAllBadgesTab(BadgesStore store) {
    var badges = store.allBadges;

    // Apply filters
    if (_selectedCategory != null) {
      badges = badges.where((b) => b.category == _selectedCategory).toList();
    }
    if (_selectedRarity != null) {
      badges = badges.where((b) => b.rarity == _selectedRarity).toList();
    }

    if (badges.isEmpty) {
      return const Center(
        child: Text('No badges available'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.02,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isEarned = store.hasBadge(badge.id);
        return _BadgeCard(
          badge: badge,
          isEarned: isEarned,
          isPrimary: store.primaryBadge?.id == badge.id,
          onTap: () => _showBadgeDetails(badge, isEarned),
        );
      },
    );
  }

  Widget _buildMyBadgesTab(BadgesStore store) {
    final myBadges = store.myBadges;

    if (myBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No badges earned yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete quests and stay active to earn badges!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.02,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: myBadges.length,
      itemBuilder: (context, index) {
        final userBadge = myBadges[index];
        return _BadgeCard(
          badge: userBadge.badge,
          isEarned: true,
          isPrimary: store.primaryBadge?.id == userBadge.badgeId,
          earnedAt: userBadge.earnedAt,
          onTap: () => _showBadgeDetails(userBadge.badge, true),
        );
      },
    );
  }

  Widget _buildProgressTab(BadgesStore store) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildStatsCard(store),
        const SizedBox(height: 18),
        _buildCategoryProgress(store),
        const SizedBox(height: 18),
        _buildRarityProgress(store),
      ],
    );
  }

  Widget _buildStatsCard(BadgesStore store) {
    final percentage = store.totalBadgeCount > 0
        ? (store.earnedBadgeCount / store.totalBadgeCount * 100)
            .toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badge Collection',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Earned', store.earnedBadgeCount.toString()),
              _buildStatItem('Total', store.totalBadgeCount.toString()),
              _buildStatItem('Progress', '$percentage%'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: store.totalBadgeCount > 0
                ? store.earnedBadgeCount / store.totalBadgeCount
                : 0,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.bgElevated,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary400),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(BadgesStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress by Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...BadgeCategory.values.map((category) {
            final totalInCategory = store.getBadgesByCategory(category).length;
            final earnedInCategory =
                store.getEarnedBadgesByCategory(category).length;
            if (totalInCategory == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProgressBar(
                category.displayName,
                earnedInCategory,
                totalInCategory,
                color: Color(category.color),
              ),
            );
          }),
          const SizedBox(height: 2),
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityProgress(BadgesStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress by Rarity',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...BadgeRarity.values.map((rarity) {
            final badgesOfRarity = store.getBadgesByRarity(rarity);
            final earnedOfRarity =
                badgesOfRarity.where((b) => store.hasBadge(b.id)).length;
            if (badgesOfRarity.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProgressBar(
                rarity.displayName,
                earnedOfRarity,
                badgesOfRarity.length,
                color: Color(rarity.color),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    int earned,
    int total, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$earned / $total',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? earned / total : 0,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: AppColors.bgElevated,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showBadgeDetails(BadgeModel badge, bool isEarned) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BadgeDetailsSheet(
        badge: badge,
        isEarned: isEarned,
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isEarned,
    required this.isPrimary,
    this.earnedAt,
    this.onTap,
  });

  final BadgeModel badge;
  final bool isEarned;
  final bool isPrimary;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(badge.rarity.color);
    final categoryColor = Color(badge.category.color);
    final unlockedBase =
        Color.lerp(rarityColor, categoryColor, 0.38) ?? rarityColor;
    final lockedOverlay = AppColors.bgBase.withValues(alpha: 0.45);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isEarned
                  ? unlockedBase.withValues(alpha: 0.24)
                  : AppColors.bgSurface.withValues(alpha: 0.95),
              isEarned
                  ? unlockedBase.withValues(alpha: 0.1)
                  : AppColors.bgSurface.withValues(alpha: 0.82),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEarned
                ? unlockedBase.withValues(alpha: 0.56)
                : AppColors.borderSubtle.withValues(alpha: 0.8),
            width: isEarned ? 1.8 : 1.2,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: unlockedBase.withValues(alpha: 0.16),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? unlockedBase.withValues(alpha: 0.18)
                              : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isEarned
                                ? unlockedBase.withValues(alpha: 0.52)
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          isEarned ? 'Unlocked' : 'Locked',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color:
                                isEarned ? unlockedBase : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isPrimary)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary500.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.primary500.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.primary400,
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: isEarned ? 1 : 0.35,
                            child: BadgeIcon(
                              badge: badge,
                              size: BadgeSize.large,
                              showTooltip: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: isEarned
                                  ? AppColors.textPrimary
                                  : AppColors.textFaint,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Opacity(
                            opacity: isEarned ? 1 : 0.45,
                            child: BadgeRarityChip(
                                rarity: badge.rarity, compact: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    isEarned
                        ? (earnedAt != null
                            ? 'Earned ${_formatDate(earnedAt!)}'
                            : 'Earned')
                        : 'Unlock at ${badge.pointsRequirement} pts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!isEarned)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: lockedOverlay,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            if (!isEarned)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$month/$day/${value.year}';
  }
}

class _BadgeDetailsSheet extends StatelessWidget {
  const _BadgeDetailsSheet({
    required this.badge,
    required this.isEarned,
  });

  final BadgeModel badge;
  final bool isEarned;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BadgesStore>();
    final isPrimary = store.primaryBadge?.id == badge.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeIcon(
              badge: badge,
              size: BadgeSize.xlarge,
              showTooltip: false,
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BadgeRarityChip(rarity: badge.rarity),
                const SizedBox(width: 8),
                BadgeCategoryChip(category: badge.category),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 24),
            if (isEarned) ...[
              if (!isPrimary)
                ElevatedButton.icon(
                  onPressed: store.isSettingPrimary
                      ? null
                      : () async {
                          final success = await store.setPrimaryBadge(badge.id);
                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${badge.name} set as primary badge'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(store.lastError ??
                                      'Failed to set primary badge'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.star),
                  label: const Text('Set as Primary Badge'),
                )
              else
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check),
                  label: const Text('Primary Badge'),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Complete requirements to unlock',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
