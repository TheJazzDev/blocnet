import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/presentation/hub_navigation.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/gem_page_top_bar.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/gem_page_view.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/handover_flow.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/main/presentation/widgets/space_bottom_nav.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/username_suggest_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One of the hunter's gems (design state 6), opened from any row or from
/// *Open gem*. Keeps the hunter bottom bar with Hub on, and has no FAB.
class HunterGemScreen extends StatefulWidget {
  const HunterGemScreen({
    super.key,
    required this.initialGem,
    this.clock,
    this.profileSearch,
  });

  /// The board row it was opened from, shown until the page's own payload
  /// arrives.
  final HunterBoardGem initialGem;
  final DateTime Function()? clock;

  /// Hand over's @username suggestions; injectable for tests.
  final ProfileSearch? profileSearch;

  @override
  State<HunterGemScreen> createState() => _HunterGemScreenState();
}

class _HunterGemScreenState extends State<HunterGemScreen> {
  String get _id => widget.initialGem.projectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HunterBoardStore>().loadGem(_id);
    });
  }

  void _selectTab(int tab) {
    final navigator = Navigator.of(context);
    if (MainTabNavigator.returnTo(navigator, tab)) return;
    if (tab == MainTabScope.hubTab) {
      navigator.maybePop();
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.main, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HunterBoardStore>();
    final detail = store.gemFor(_id);
    final gem = detail?.gem ?? _boardCopy(store) ?? widget.initialGem;
    final now = (widget.clock ?? DateTime.now)();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GemPageTopBar(
              onBack: () => Navigator.of(context).maybePop(),
              onViewAsMember: () => showGemDetailsDialog(context, _id),
            ),
            Expanded(
              child: GemPageView(
                gem: gem,
                detail: detail,
                loading: store.isLoadingGem(_id),
                error: store.gemErrorFor(_id),
                now: now,
                onPost: () =>
                    HubNavigation.openComposer(context, projectId: _id),
                onHandover: () => HandoverFlow.open(
                  context,
                  projectId: _id,
                  gemName: gem.name,
                  pending: detail?.pendingHandover,
                  now: now,
                  search: widget.profileSearch,
                ),
                onEdit: (event) => HubNavigation.openComposer(
                  context,
                  projectId: _id,
                  updateId: event.id,
                ),
                onRetry: () => store.loadGem(_id),
                onRefresh: () => Future.wait([
                  store.loadGem(_id),
                  store.loadBoard(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SpaceBottomNav(
        space: NavSpace.hunter,
        currentIndex: MainTabScope.hubTab,
        onTap: _selectTab,
      ),
    );
  }

  /// The gem as the latest board has it, so a refreshed board updates the
  /// page even before its own payload returns.
  HunterBoardGem? _boardCopy(HunterBoardStore store) {
    final gems = store.board?.gems;
    if (gems == null) return null;
    for (final gem in gems) {
      if (gem.projectId == _id) return gem;
    }
    return null;
  }
}
