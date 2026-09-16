import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_earn_faster_cards.dart';
import 'package:blocnet/features/mining/presentation/widgets/leaderboard/mine_leaderboard_row.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:flutter/material.dart';

/// Whether the member's own row is on the page being shown.
bool mineMeOnPage(
  MiningLeaderboardEntry me,
  List<MiningLeaderboardEntry> page,
) {
  return page.any((entry) => entry.userId == me.userId);
}

/// The pinned row shows while the member is ranked and their row is not on
/// screen: either on another page, or scrolled out of view.
bool mineShouldPinMe({
  required MiningLeaderboardEntry? me,
  required List<MiningLeaderboardEntry> page,
  required bool meRowVisible,
}) {
  if (me == null) return false;
  if (!mineMeOnPage(me, page)) return true;
  return !meRowVisible;
}

/// Mine tab's Leaderboard section: top three plus the member's own row.
/// The whole block opens the full board.
class MineLeaderboardPreview extends StatelessWidget {
  const MineLeaderboardPreview({
    super.key,
    required this.top,
    required this.me,
    required this.onOpen,
  });

  final List<MiningLeaderboardEntry> top;
  final MiningLeaderboardEntry? me;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final mine = me;
    final showMine = mine != null && !mineMeOnPage(mine, top);
    final rows = [...top, if (showMine) mine];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MineSectionHeader(
          icon: Icons.leaderboard_outlined,
          title: 'Leaderboard',
          trailing: mine == null ? null : 'You · #${mine.rank}',
          onTap: onOpen,
        ),
        if (rows.isNotEmpty)
          GestureDetector(
            key: const ValueKey('mine-leaderboard-preview'),
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: MineEarnCardFrame(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    MineLeaderboardRow(
                      entry: rows[i],
                      divided: i < rows.length - 1,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
