import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/chain_chip.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A current gem, condensed to one line: logo, name, chain, followers, when
/// it was last touched, a tick.
class GemCurrentRow extends StatelessWidget {
  const GemCurrentRow({
    super.key,
    required this.gem,
    required this.now,
    required this.onOpen,
  });

  final HunterBoardGem gem;
  final DateTime now;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HubInsets.gutter,
          vertical: AppSpace.md + 2,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            GemMonogram(
              name: gem.name,
              tag: gem.chain,
              size: GemMonogramSize.small,
            ),
            AppSpace.wGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gem.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.rowTitle(AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Row(
                    children: [
                      ChainChip(tag: gem.chain),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${groupedCount(gem.followersCount)} · '
                          '${shortAgo(gem.lastTouchedAt, now)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HubType.meta(AppColors.textFaint),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpace.wGapSm,
            Icon(
              Icons.check_circle_rounded,
              size: AppIcon.sm,
              color: HubTone.current,
            ),
          ],
        ),
      ),
    );
  }
}
