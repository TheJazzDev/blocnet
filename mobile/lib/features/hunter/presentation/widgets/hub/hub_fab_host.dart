import 'package:blocnet/features/hunter/presentation/hub_navigation.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/hub_fab.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Chooses the Hub FAB from the board: *Submit a gem* with no gems, *Post
/// update* otherwise. Nothing while the first load is in flight, so the
/// button never switches under the hunter's thumb.
class HubFabHost extends StatelessWidget {
  const HubFabHost({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HunterBoardStore>();
    final board = store.board;
    if (board == null && store.boardError == null) {
      return const SizedBox.shrink();
    }
    return HubFab(
      dayOne: board != null && board.gems.isEmpty,
      onPostUpdate: () => HubNavigation.openComposer(context),
      onSubmitGem: () => HubNavigation.openSubmit(context),
    );
  }
}
