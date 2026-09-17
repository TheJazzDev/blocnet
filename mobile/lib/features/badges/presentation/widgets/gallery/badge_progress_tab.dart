import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The gallery's Progress tab: two stat tiles, then flat cards with a bar
/// per category and per rarity.
class BadgeProgressTab extends StatelessWidget {
  const BadgeProgressTab({super.key, required this.store});

  final BadgesStore store;

  @override
  Widget build(BuildContext context) {
    final earned = store.earnedBadgeCount;
    final total = store.totalBadgeCount;
    final percent = total > 0 ? (earned / total * 100).round() : 0;

    final categories = [
      for (final category in BadgeCategory.values)
        if (store.getBadgesByCategory(category).isNotEmpty)
          _Bar(
            label: category.displayName,
            earned: store.getEarnedBadgesByCategory(category).length,
            total: store.getBadgesByCategory(category).length,
            color: category.tone,
          ),
    ];
    final rarities = [
      for (final rarity in BadgeRarity.values)
        if (store.getBadgesByRarity(rarity).isNotEmpty)
          _Bar(
            label: rarity.displayName,
            earned: store
                .getBadgesByRarity(rarity)
                .where((b) => store.hasBadge(b.id))
                .length,
            total: store.getBadgesByRarity(rarity).length,
            color: rarity.tone,
          ),
    ];

    return ListView(
      padding: AppSpace.allLg,
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                label: 'Earned',
                value: '$earned of $total',
                icon: Icons.emoji_events_outlined,
                iconColor: AppColors.warning500,
              ),
            ),
            AppSpace.wGapMd,
            Expanded(
              child: AppStatTile(
                label: 'Collected',
                value: '$percent%',
                icon: Icons.donut_large_rounded,
              ),
            ),
          ],
        ),
        AppSpace.gapLg,
        if (categories.isNotEmpty)
          _BarCard(
            icon: Icons.category_outlined,
            label: 'By category',
            bars: categories,
          ),
        if (rarities.isNotEmpty) ...[
          AppSpace.gapLg,
          _BarCard(
            icon: Icons.auto_awesome_outlined,
            label: 'By rarity',
            bars: rarities,
          ),
        ],
      ],
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({
    required this.icon,
    required this.label,
    required this.bars,
  });

  final IconData icon;
  final String label;
  final List<_Bar> bars;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: label,
            icon: icon,
            padding: const EdgeInsets.only(bottom: AppSpace.md),
          ),
          for (var i = 0; i < bars.length; i++) ...[
            if (i > 0) AppSpace.gapMd,
            bars[i],
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.earned,
    required this.total,
    required this.color,
  });

  final String label;
  final int earned;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.label(
                  AppColors.textSecondary,
                  weight: AppText.semibold,
                ),
              ),
            ),
            Text(
              '$earned / $total',
              style:
                  AppText.caption(AppColors.textMuted).merge(AppText.tabular),
            ),
          ],
        ),
        AppSpace.gapXs,
        LinearProgressIndicator(
          value: total > 0 ? earned / total : 0,
          minHeight: 5,
          borderRadius: AppRadius.full,
          backgroundColor: AppColors.bgElevated,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
