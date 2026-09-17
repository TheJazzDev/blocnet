import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/domain/gems_ordering.dart';
import 'package:blocnet/features/gems/presentation/widgets/discover/discover_controls.dart';
import 'package:blocnet/features/gems/presentation/widgets/discover/discover_gem_card.dart';
import 'package:blocnet/features/gems/presentation/widgets/discover/moving_section.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_notice.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:flutter/material.dart';

/// Discover: what is moving, then every gem with its keeper.
class DiscoverView extends StatelessWidget {
  const DiscoverView({
    super.key,
    required this.state,
    required this.gems,
    required this.sort,
    required this.tag,
    required this.now,
    required this.actions,
    required this.onSort,
    required this.onSelectTag,
    required this.onRefresh,
  });

  final GemsLoadState state;

  /// Every listed gem, unfiltered.
  final List<GemListing> gems;
  final GemSort sort;
  final String? tag;
  final DateTime now;
  final GemActions actions;
  final ValueChanged<GemSort> onSort;
  final ValueChanged<String?> onSelectTag;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return GemsScrollView(
      storageKey: 'gems-discover',
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
              title: "Couldn't load gems",
              message: 'Check your connection.',
              actionLabel: 'Try again',
              onAction: onRefresh,
            ),
          ],
        GemsLoadState.ready => const [
            GemsNotice(
              icon: Icons.diamond_outlined,
              title: 'No gems listed yet',
              message: 'Hunters list gems here as they find them.',
            ),
          ],
      };
    }

    final visible = GemsOrdering.discover(gems, sort: sort, tag: tag);
    return [
      MovingSection(
        gems: GemsOrdering.moving(gems, now),
        now: now,
        onOpen: actions.onOpen,
      ),
      DiscoverControls(
        count: visible.length,
        sort: sort,
        onSort: onSort,
        tags: GemsOrdering.tags(gems),
        selectedTag: tag,
        onSelectTag: onSelectTag,
      ),
      AppSpace.gapMd,
      if (visible.isEmpty)
        GemsNotice(
          icon: Icons.filter_alt_off_outlined,
          title: 'No ${tag ?? ''} gems',
          message: 'Nothing is listed on this chain yet.',
          actionLabel: 'Show all gems',
          onAction: () => onSelectTag(null),
        )
      else
        for (final gem in visible)
          DiscoverGemCard(gem: gem, actions: actions, now: now),
    ];
  }
}
