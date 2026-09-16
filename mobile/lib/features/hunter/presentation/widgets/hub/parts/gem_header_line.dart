import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/chain_chip.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_state_chip.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// Monogram · name · chain chip and `N following` · state chip.
///
/// The row uses the 40px monogram and a 15px name; the gem page the 52px
/// monogram and a 20px name ([large]).
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: large
                    ? AppTypography.custom(
                        size: 20,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                        height: 1.25,
                      )
                    : HubType.rowTitle(AppColors.textPrimary),
              ),
              SizedBox(height: large ? 4 : 3),
              Row(
                children: [
                  ChainChip(tag: gem.chain),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${groupedCount(gem.followersCount)} following',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HubType.meta(AppColors.zincDim),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GemStateChip(chip: gem.chip),
      ],
    );
  }
}
