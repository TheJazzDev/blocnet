import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/services/badges_store.dart';
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
    _loadBadges();
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
      appBar: AppBar(
        title: const Text('Badges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Badges'),
            Tab(text: 'My Badges'),
            Tab(text: 'Progress'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<BadgesStore>(
        builder: (context, store, child) {
          if (store.isLoadingAll || store.isLoadingMy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (store.lastError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
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
        childAspectRatio: 0.85,
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
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade600),
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
        childAspectRatio: 0.85,
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
        const SizedBox(height: 16),
        _buildCategoryProgress(store),
        const SizedBox(height: 16),
        _buildRarityProgress(store),
      ],
    );
  }

  Widget _buildStatsCard(BadgesStore store) {
    final percentage = store.totalBadgeCount > 0
        ? (store.earnedBadgeCount / store.totalBadgeCount * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Badge Collection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Earned', store.earnedBadgeCount.toString()),
                _buildStatItem('Total', store.totalBadgeCount.toString()),
                _buildStatItem('Progress', '$percentage%'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: store.totalBadgeCount > 0
                  ? store.earnedBadgeCount / store.totalBadgeCount
                  : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(BadgesStore store) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...BadgeCategory.values.map((category) {
              final totalInCategory =
                  store.getBadgesByCategory(category).length;
              final earnedInCategory =
                  store.getEarnedBadgesByCategory(category).length;
              if (totalInCategory == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProgressBar(
                  category.displayName,
                  earnedInCategory,
                  totalInCategory,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityProgress(BadgesStore store) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Rarity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...BadgeRarity.values.map((rarity) {
              final badgesOfRarity = store.getBadgesByRarity(rarity);
              final earnedOfRarity = badgesOfRarity
                  .where((b) => store.hasBadge(b.id))
                  .length;
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
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              '$earned / $total',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? earned / total : 0,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Badges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...BadgeCategory.values.map((cat) => FilterChip(
                        label: Text(cat.displayName),
                        selected: _selectedCategory == cat,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Rarity', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedRarity == null,
                    onSelected: (_) {
                      setState(() => _selectedRarity = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...BadgeRarity.values.map((rarity) => FilterChip(
                        label: Text(rarity.displayName),
                        selected: _selectedRarity == rarity,
                        onSelected: (_) {
                          setState(() => _selectedRarity = rarity);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Opacity(
              opacity: isEarned ? 1.0 : 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BadgeIcon(
                    badge: badge,
                    size: BadgeSize.xlarge,
                    showTooltip: false,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  BadgeRarityChip(rarity: badge.rarity, compact: true),
                ],
              ),
            ),
            if (isPrimary)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.star, size: 16, color: Colors.white),
                ),
              ),
            if (!isEarned)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Locked',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
                                  content: Text('${badge.name} set as primary badge'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(store.lastError ?? 'Failed to set primary badge'),
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
