import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/chain_chip.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_state_chip.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// Monogram · name · chain tag and `N following` · state pill.
///
/// Rows use the 40px monogram and a 14px name; the gem page the 44px
/// monogram and an 18px name ([large]).
class GemHeaderLine extends StatelessWidget {
  const GemHeaderLine({super.key, required this.gem, this.large = false});

  final HunterBoardGem gem;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GemMonogram(
          name: gem.name,
          tag: gem.chain,
          size: large ? GemMonogramSize.large : GemMonogramSize.medium,
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
                style: large
                    ? AppText.title(AppColors.textPrimary)
                    : HubType.rowTitle(AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpace.xs),
              Row(
                children: [
                  ChainChip(tag: gem.chain),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${groupedCount(gem.followersCount)} following',
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
        GemStateChip(chip: gem.chip),
      ],
    );
  }
}
