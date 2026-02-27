import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

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
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: accentColor,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: accentColor,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.custom(
          size: 13,
          color: Colors.black,
          weight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.custom(
          size: 13,
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Market Talk'),
        ],
      ),
    );
  }
}
