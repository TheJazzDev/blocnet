import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/domain/gems_ordering.dart';
import 'package:blocnet/features/gems/presentation/widgets/board/board_row.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_notice.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// Your board: the gems the member follows, most in need of them first.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.gems,
    required this.now,
    required this.actions,
    required this.onDiscover,
    required this.onRefresh,
  });

  final GemsLoadState state;

  /// The followed gems, in any order.
  final List<GemListing> gems;
  final DateTime now;
  final GemActions actions;
  final VoidCallback onDiscover;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return GemsScrollView(
      storageKey: 'gems-board',
      onRefresh: onRefresh,
      children: _children(),
    );
  }

  List<Widget> _children() {
    if (gems.isEmpty) {
      return switch (state) {
        GemsLoadState.loading => const [GemsLoading()],
        GemsLoadState.error => [
            GemsNotice(
              icon: Icons.cloud_off_rounded,
              title: "Couldn't load your board",
              message: 'Check your connection.',
              actionLabel: 'Try again',
              onAction: onRefresh,
            ),
          ],
        GemsLoadState.ready => [
            GemsNotice(
              icon: Icons.dashboard_customize_outlined,
              title: 'Your board is empty',
              message: "Pick the gems you're farming. "
                  'A hunter keeps each one covered.',
              actionLabel: 'Discover gems',
              onAction: onDiscover,
            ),
          ],
      };
    }

    final ordered = GemsOrdering.board(gems, now);
    final quiet = ordered.where((g) => g.isQuiet).length;
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md),
        child: Text(
          [
            'FOLLOWING ${ordered.length}',
            if (quiet > 0) '$quiet QUIET',
          ].join(' · '),
          style: HubType.caps(AppColors.textFaint),
        ),
      ),
      for (final gem in ordered)
        BoardRow(gem: gem, actions: actions, now: now),
    ];
  }
}
