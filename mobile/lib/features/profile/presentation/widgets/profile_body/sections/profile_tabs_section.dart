import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_activity_tab.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_following_tab.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_saved_tab.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_bar.dart';
import 'package:flutter/material.dart';

/// Activity / Following / Saved tabs. Shown to everyone.
class ProfileTabsSection extends StatefulWidget {
  const ProfileTabsSection({super.key, required this.accent});

  final Color accent;

  @override
  State<ProfileTabsSection> createState() => _ProfileTabsSectionState();
}

class _ProfileTabsSectionState extends State<ProfileTabsSection> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileTabBar(
          tabs: const ['Activity', 'Following', 'Saved'],
          activeIndex: _tabIndex,
          accent: widget.accent,
          onChanged: (i) => setState(() => _tabIndex = i),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
          child: Text(
            switch (_tabIndex) {
              0 => 'Your actions on Blocnet.',
              1 => 'Gems you follow are listed here for quick access.',
              _ => 'Items you bookmarked to revisit later.',
            },
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
            child: switch (_tabIndex) {
              0 => ProfileActivityTab(accent: widget.accent),
              1 => ProfileFollowingTab(accent: widget.accent),
              _ => ProfileSavedTab(accent: widget.accent),
            },
          ),
        ),
      ],
    );
  }
}
