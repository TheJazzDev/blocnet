import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/profile/domain/reliability_summary.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/reliability_line.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The one hunter block left on Profile, for hunters only: reliability once
/// (standing and current gems) and the way into the Hub. Stats, signals and
/// content shortcuts live on the Hub.
class HunterHubLinkSection extends StatefulWidget {
  const HunterHubLinkSection({super.key, required this.inHunterSpace});

  /// In the hunter space the Hub is a tab, so the row switches to it rather
  /// than stacking a second copy.
  final bool inHunterSpace;

  @override
  State<HunterHubLinkSection> createState() => _HunterHubLinkSectionState();
}

class _HunterHubLinkSectionState extends State<HunterHubLinkSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<HunterBoardStore?>();
      if (store != null && store.board == null) store.loadBoard();
    });
  }

  void _openHub() {
    if (widget.inHunterSpace) {
      MainTabNavigator.open(
        context,
        MainTabScope.hubTab,
        fallbackRoute: AppRoutes.hunterHub,
      );
    } else {
      Navigator.of(context).pushNamed(AppRoutes.hunterHub);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optional so the row still works where the store is not provided.
    final board = context.watch<HunterBoardStore?>()?.board;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hunter', icon: Icons.shield_outlined),
          AppSpace.gapSm,
          AppRowGroup(
            children: [
              AppListRow(
                key: const ValueKey('profile-hunter-hub'),
                icon: Icons.shield_outlined,
                title: 'Hunter Hub',
                subtitle: board == null ? 'Your gems and updates' : null,
                subtitleWidget: board == null
                    ? null
                    : ReliabilityLine(
                        key: const ValueKey('profile-reliability'),
                        summary: ReliabilitySummary.fromBoard(board),
                      ),
                onTap: _openHub,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
