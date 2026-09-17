import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/keeper_avatar.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/standing_pill.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:flutter/material.dart';

/// One hunter in the ranking: rank, name, standing, and the numbers behind
/// it. Reach (followers) sits after reliability, never in front of it.
class HunterRankRow extends StatelessWidget {
  const HunterRankRow({
    super.key,
    required this.rank,
    required this.keeper,
    required this.keepsYourGems,
    required this.divider,
    required this.onTap,
  });

  final int rank;
  final GemKeeper keeper;

  /// The hunter keeps a gem the member follows.
  final bool keepsYourGems;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('hunter-row-${keeper.profileId}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          border: divider
              ? const Border(top: BorderSide(color: AppColors.borderSubtle))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: HubType.meta(AppColors.textFaint, weight: AppText.bold),
              ),
            ),
            KeeperAvatar(
              name: keeper.name,
              imageUrl: keeper.avatarUrl,
              radius: 18,
            ),
            AppSpace.wGapMd,
            Expanded(
                child: _Details(keeper: keeper, keepsYourGems: keepsYourGems)),
            AppSpace.wGapSm,
            StandingPill(standing: keeper.standing),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.keeper, required this.keepsYourGems});

  final GemKeeper keeper;
  final bool keepsYourGems;

  @override
  Widget build(BuildContext context) {
    final coverage = keeper.coverageLine;
    final gems = keeper.gemsOwned ?? 0;
    final first = coverage ?? counted(gems, 'gem');
    final second = [
      if (_response != null) _response!,
      '${groupedCount(keeper.followersTotal ?? 0)} following',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                keeper.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HubType.rowTitle(AppColors.textPrimary),
              ),
            ),
            if (keeper.level != null) ...[
              AppSpace.wGapXs,
              LevelBadgeIcon(level: keeper.level!, size: LevelBadgeSize.tiny),
            ],
          ],
        ),
        Text(
          first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HubType.meta(AppColors.textSecondary),
        ),
        Text(
          second,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HubType.meta(AppColors.textFaint),
        ),
        if (keepsYourGems)
          Text(
            'Keeps your gems',
            key: const ValueKey('keeps-your-gems'),
            style: HubType.meta(AppColors.primary500, weight: AppText.semibold),
          ),
      ],
    );
  }

  /// "Answered 4 of 5 asks", or a share when the counts are missing.
  String? get _response {
    final asked = keeper.responseAsked;
    final answered = keeper.responseAnswered;
    if (asked != null && answered != null && asked > 0) {
      return 'Answered $answered of $asked asks';
    }
    final share = keeper.response;
    if (share == null) return null;
    return 'Answered ${(share * 100).round()}% of asks';
  }
}
