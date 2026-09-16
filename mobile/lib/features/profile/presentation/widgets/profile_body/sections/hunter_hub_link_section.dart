import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_tile.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:flutter/material.dart';

/// The one hunter entry left on Profile. Stats, signals, community voice and
/// the content shortcuts moved to the Hub; this row takes the hunter there.
class HunterHubLinkSection extends StatelessWidget {
  const HunterHubLinkSection({super.key, required this.inHunterSpace});

  /// In the hunter space the Hub is a tab, so the row switches to it rather
  /// than stacking a second copy.
  final bool inHunterSpace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hunter'),
          const SizedBox(height: AppSpace.sm),
          ProfileTile(
            key: const ValueKey('profile-hunter-hub'),
            icon: Icons.shield_outlined,
            title: 'Hunter Hub',
            subtitle: 'Your gems, who is waiting, and your updates',
            showDivider: false,
            onTap: () {
              if (inHunterSpace) {
                MainTabNavigator.open(
                  context,
                  MainTabScope.hubTab,
                  fallbackRoute: AppRoutes.hunterHub,
                );
              } else {
                Navigator.of(context).pushNamed(AppRoutes.hunterHub);
              }
            },
          ),
        ],
      ),
    );
  }
}
