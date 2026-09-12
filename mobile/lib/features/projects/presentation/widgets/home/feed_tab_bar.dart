import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedTabDelegate extends SliverPersistentHeaderDelegate {
  const FeedTabDelegate({
    required this.activeSection,
    required this.onTabChanged,
  });

  final Section activeSection;
  final ValueChanged<Section> onTabChanged;

  static const double _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(FeedTabDelegate oldDelegate) =>
      oldDelegate.activeSection != activeSection;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return FeedTabBar(
      activeSection: activeSection,
      onTabChanged: onTabChanged,
    );
  }
}

class FeedTabBar extends StatelessWidget {
  const FeedTabBar({
    super.key,
    required this.activeSection,
    required this.onTabChanged,
  });

  final Section activeSection;
  final ValueChanged<Section> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final accent =
        AppColors.accentForSpace(context.watch<AuthStore>().isInHunterSpace);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      // One tab set, used in every state. Round six settled this: the canvas
      // had been showing three different sets, and "Updates", "For you" and
      // "Following" were being used interchangeably for different things.
      child: Row(
        children: [
          for (final section in Sections.homeTabs)
            FeedTabItem(
              label: section.label,
              isActive: activeSection == section,
              accentColor: accent,
              onTap: () => onTabChanged(section),
            ),
        ],
      ),
    );
  }
}

class FeedTabItem extends StatelessWidget {
  const FeedTabItem({
    super.key,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        height: 44,
        child: Text(
          label,
          style: AppTypography.custom(
            color: isActive ? accentColor : AppColors.textFaint,
            size: AppText.bodySize,
            weight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
