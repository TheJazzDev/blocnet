import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_activity_tab.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_saved_tab.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_bar.dart';
import 'package:flutter/material.dart';

/// Activity / Saved tabs. Shown to everyone. Followed gems are not a tab:
/// they live in Gems › Your board, reached from the "Gems followed" tile.
class ProfileTabsSection extends StatefulWidget {
  const ProfileTabsSection({
    super.key,
    required this.accent,
    this.onOpenActivity,
  });

  static const List<String> tabs = ['Activity', 'Saved'];

  final Color accent;

  /// Overrides where Activity rows go; tests use it.
  final ActivityTargetOpener? onOpenActivity;

  @override
  State<ProfileTabsSection> createState() => _ProfileTabsSectionState();
}

class _ProfileTabsSectionState extends State<ProfileTabsSection> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final opener = widget.onOpenActivity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileTabBar(
            tabs: ProfileTabsSection.tabs,
            activeIndex: _tabIndex,
            accent: widget.accent,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          AppSpace.gapMd,
          if (_tabIndex == 0)
            opener == null
                ? ProfileActivityTab(accent: widget.accent)
                : ProfileActivityTab(accent: widget.accent, onOpen: opener)
          else
            ProfileSavedTab(accent: widget.accent),
        ],
      ),
    );
  }
}
