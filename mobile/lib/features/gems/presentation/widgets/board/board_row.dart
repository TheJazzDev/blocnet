import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/board/board_row_menu.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gem_activity_line.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_button.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_tone.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/chain_chip.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A followed gem on the member's board: its newest update, its next
/// deadline, and a QUIET pill with *Ask* when its hunter has gone quiet.
class BoardRow extends StatelessWidget {
  const BoardRow({
    super.key,
    required this.gem,
    required this.actions,
    required this.now,
  });

  final GemListing gem;
  final GemActions actions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final project = gem.project;
    final deadline = gem.nextDeadline?.deadlineAt;
    final keeper = gem.keeper;

    return Container(
      key: ValueKey('board-row-${project.id}'),
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.md,
          onTap: () => actions.onOpen(gem),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: GemMonogram(
                    name: project.name,
                    tag: project.primaryTag.name,
                    size: GemMonogramSize.small,
                  ),
                ),
                AppSpace.wGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleLine(gem: gem),
                      AppSpace.gapXs,
                      GemActivityLine(gem: gem, now: now),
                      if (deadline != null)
                        FeedDeadlineLine(deadlineAt: deadline, now: now),
                      if (gem.isQuiet) ...[
                        AppSpace.gapXs,
                        Text(
                          'No update for ${counted(now.difference(gem.lastActivity).inDays, 'day')}',
                          style: HubType.meta(GemsTone.quiet),
                        ),
                        AppSpace.gapSm,
                        GemsButton(
                          key: ValueKey('board-ask-${project.id}'),
                          label: keeper?.handle == null
                              ? 'Ask for an update'
                              : 'Ask ${keeper!.handle}',
                          icon: Icons.campaign_outlined,
                          filled: false,
                          small: true,
                          onTap: () => actions.onAsk(gem),
                        ),
                      ],
                    ],
                  ),
                ),
                BoardRowMenu(gem: gem, actions: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleLine extends StatelessWidget {
  const _TitleLine({required this.gem});

  final GemListing gem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gem.project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HubType.rowTitle(AppColors.textPrimary),
        ),
        AppSpace.gapXs,
        Wrap(
          spacing: AppSpace.xs + 2,
          runSpacing: AppSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChainChip(tag: gem.project.primaryTag.name),
            if (gem.isQuiet)
              AppPill.caps(
                key: ValueKey('quiet-pill'),
                label: 'Quiet',
                color: GemsTone.quiet,
              ),
          ],
        ),
      ],
    );
  }
}
