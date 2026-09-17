import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:flutter/material.dart';

/// General / Market Talk, with the member's Saved posts and a ⋯ menu (My
/// reports) at the end of the row. The tab's app bar belongs to the main
/// shell, so Community's own shortcuts live here.
class CommunityTabs extends StatelessWidget {
  const CommunityTabs({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  final TabController controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.only(left: AppSpace.sm),
              labelPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              labelColor: accentColor,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: accentColor,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: AppTypography.custom(
                size: AppText.bodySize,
                color: accentColor,
                weight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTypography.custom(
                size: AppText.bodySize,
                color: AppColors.textMuted,
                weight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'General'),
                Tab(text: 'Market Talk'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Saved',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.communitySaved),
            icon: Icon(
              Icons.bookmark_border_rounded,
              size: AppIcon.md,
              color: AppColors.textSecondary,
            ),
          ),
          const _CommunityOverflow(),
        ],
      ),
    );
  }
}

enum _OverflowItem { saved, reports }

class _CommunityOverflow extends StatelessWidget {
  const _CommunityOverflow();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OverflowItem>(
      tooltip: 'More',
      color: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      icon: Icon(
        Icons.more_vert_rounded,
        size: AppIcon.md,
        color: AppColors.textSecondary,
      ),
      onSelected: (item) => Navigator.of(context).pushNamed(
        switch (item) {
          _OverflowItem.saved => AppRoutes.communitySaved,
          _OverflowItem.reports => AppRoutes.myReports,
        },
      ),
      itemBuilder: (_) => [
        _item(
            _OverflowItem.saved, Icons.bookmark_border_rounded, 'Saved posts'),
        _item(_OverflowItem.reports, Icons.flag_outlined, 'My reports'),
      ],
    );
  }

  PopupMenuItem<_OverflowItem> _item(
    _OverflowItem value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_OverflowItem>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm, color: AppColors.textSecondary),
          const SizedBox(width: AppSpace.md),
          Text(
            label,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
