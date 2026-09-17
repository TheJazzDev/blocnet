import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/presentation/widgets/hunters/hunter_rank_row.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_button.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_notice.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// Hunters: one ranking by reliability, as the server orders it.
class HuntersView extends StatelessWidget {
  const HuntersView({
    super.key,
    required this.state,
    required this.entries,
    required this.yourHunterIds,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onOpen,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final GemsLoadState state;
  final List<HunterLeaderboardEntry> entries;

  /// Hunters who keep a gem the member follows.
  final Set<String> yourHunterIds;
  final bool hasMore;
  final bool isLoadingMore;
  final ValueChanged<GemKeeper> onOpen;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return GemsScrollView(
      storageKey: 'gems-hunters',
      onRefresh: onRefresh,
      children: _children(),
    );
  }

  List<Widget> _children() {
    if (entries.isEmpty) {
      return switch (state) {
        GemsLoadState.loading => const [GemsLoading()],
        GemsLoadState.error => [
            GemsNotice(
              icon: Icons.cloud_off_rounded,
              title: "Couldn't load hunters",
              message: 'Check your connection.',
              actionLabel: 'Try again',
              onAction: onRefresh,
            ),
          ],
        GemsLoadState.ready => const [
            GemsNotice(
              icon: Icons.shield_outlined,
              title: 'No hunters ranked yet',
              message: 'Hunters appear once they keep a live gem.',
            ),
          ],
      };
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md),
        child: Text(
          'RANKED BY RELIABILITY',
          style: HubType.caps(AppColors.textFaint),
        ),
      ),
      HomePanel(
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++)
              _row(entries[i], divider: i > 0),
          ],
        ),
      ),
      if (hasMore) ...[
        AppSpace.gapMd,
        GemsButton(
          key: const ValueKey('hunters-more'),
          label: isLoadingMore ? 'Loading…' : 'Show more hunters',
          filled: false,
          expand: true,
          onTap: isLoadingMore ? null : onLoadMore,
        ),
      ],
    ];
  }

  Widget _row(HunterLeaderboardEntry entry, {required bool divider}) {
    final keeper = GemKeeper.fromReliability(entry.reliability);
    return HunterRankRow(
      rank: entry.rank,
      keeper: keeper,
      keepsYourGems: yourHunterIds.contains(keeper.profileId),
      divider: divider,
      onTap: () => onOpen(keeper),
    );
  }
}
