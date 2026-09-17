import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/keeper_avatar.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/standing_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:flutter/material.dart';

/// `Kept by @hunter [level] · 4 of 5 gems current  RELIABLE`.
class KeeperLine extends StatelessWidget {
  const KeeperLine({super.key, required this.keeper, this.onTap});

  final GemKeeper keeper;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final coverage = keeper.coverageLine;
    return GestureDetector(
      key: ValueKey('keeper-${keeper.profileId}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          KeeperAvatar(name: keeper.label, imageUrl: keeper.avatarUrl),
          AppSpace.wGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Kept by ${keeper.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HubType.meta(
                          AppColors.textSecondary,
                          weight: AppText.semibold,
                        ),
                      ),
                    ),
                    if (keeper.level != null) ...[
                      AppSpace.wGapXs,
                      LevelBadgeIcon(
                        level: keeper.level!,
                        size: LevelBadgeSize.tiny,
                      ),
                    ],
                  ],
                ),
                if (coverage != null)
                  Text(
                    coverage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.meta(AppColors.textFaint),
                  ),
              ],
            ),
          ),
          AppSpace.wGapSm,
          StandingPill(standing: keeper.standing),
        ],
      ),
    );
  }
}
