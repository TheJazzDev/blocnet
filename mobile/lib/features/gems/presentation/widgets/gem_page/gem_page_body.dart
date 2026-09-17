import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_page/gem_keeper_card.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_page/gem_quiet_notice.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_page/gem_summary_card.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_page/gem_update_timeline.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_notice.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:flutter/material.dart';

/// What the gem page's callers can ask for.
class GemPageCallbacks {
  const GemPageCallbacks({
    required this.onToggleFollow,
    required this.onPreferences,
    required this.onOpenKeeper,
    required this.onAsk,
    required this.onOpenUpdate,
    required this.onRetryUpdates,
    required this.onRefresh,
  });

  final VoidCallback onToggleFollow;
  final VoidCallback onPreferences;
  final ValueChanged<GemKeeper> onOpenKeeper;
  final VoidCallback onAsk;
  final ValueChanged<Update> onOpenUpdate;
  final VoidCallback onRetryUpdates;
  final Future<void> Function() onRefresh;
}

/// The member's gem page: the gem, who keeps it, and its updates.
class GemPageBody extends StatelessWidget {
  const GemPageBody({
    super.key,
    required this.gem,
    required this.updates,
    required this.updatesState,
    required this.isFollowed,
    required this.now,
    required this.callbacks,
  });

  final GemListing gem;

  /// Newest first.
  final List<Update> updates;
  final GemsLoadState updatesState;
  final bool isFollowed;
  final DateTime now;
  final GemPageCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final project = gem.project;
    final keeper = gem.keeper;
    final details = project.details.trim();
    final quietDays =
        gem.isQuiet ? now.difference(gem.lastActivity).inDays : null;

    return GemsScrollView(
      onRefresh: callbacks.onRefresh,
      children: [
        GemSummaryCard(
          gem: gem,
          isFollowed: isFollowed,
          now: now,
          onToggleFollow: callbacks.onToggleFollow,
          onPreferences: callbacks.onPreferences,
        ),
        if (quietDays != null)
          GemQuietNotice(
            days: quietDays,
            handle: keeper?.handle,
            onAsk: isFollowed ? callbacks.onAsk : null,
          ),
        if (keeper != null)
          GemKeeperCard(
            keeper: keeper,
            onOpen: () => callbacks.onOpenKeeper(keeper),
          ),
        if (details.isNotEmpty && details != project.description.trim()) ...[
          const _Heading('About'),
          RenderMarkdownContent(content: details),
          AppSpace.gapLg,
        ],
        const _Heading('Updates'),
        ..._timeline(quietDays),
      ],
    );
  }

  List<Widget> _timeline(int? quietDays) {
    if (updates.isNotEmpty) {
      return [
        GemUpdateTimeline(
          updates: updates,
          now: now,
          gapDays: quietDays,
          onOpen: callbacks.onOpenUpdate,
        ),
      ];
    }
    return switch (updatesState) {
      GemsLoadState.loading => const [GemsLoading()],
      GemsLoadState.error => [
          GemsNotice(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load updates",
            actionLabel: 'Try again',
            onAction: callbacks.onRetryUpdates,
          ),
        ],
      GemsLoadState.ready => const [
          GemsNotice(
            icon: Icons.hourglass_empty_rounded,
            title: 'No updates yet',
            message: 'Follow to hear when the hunter posts.',
          ),
        ],
    };
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.md),
      child: Text(
        label.toUpperCase(),
        style: HubType.caps(AppColors.textFaint),
      ),
    );
  }
}
