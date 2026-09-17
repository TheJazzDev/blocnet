import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_member_parts.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Amber for the top three, as the old board; muted otherwise.
Color mineRankColor(int rank) =>
    rank <= 3 ? MinePalette.amber : MinePalette.muted;

/// Opens [entry]'s public profile sheet.
Future<void> openMineMemberProfile(
  BuildContext context,
  MiningLeaderboardEntry entry,
) {
  return PublicProfileScreen.showSheet(
    context,
    Admin(
      id: entry.userId,
      name: mineMemberName(entry.displayName, entry.username),
      username: entry.username ?? '',
      imageUrl: entry.avatarUrl ?? '',
      followers: 0,
      currentLevel: entry.currentLevel,
    ),
  );
}

/// Rank · avatar · name + level · @handle + mining now · lifetime BNP.
class MineLeaderboardRow extends StatelessWidget {
  const MineLeaderboardRow({
    super.key,
    required this.entry,
    this.onTap,
    this.divided = true,
    this.nameOverride,
  });

  final MiningLeaderboardEntry entry;

  /// `You` on the pinned row.
  final String? nameOverride;
  final VoidCallback? onTap;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final name =
        nameOverride ?? mineMemberName(entry.displayName, entry.username);
    final handle = entry.username?.trim();
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: divided
            ? const Border(bottom: BorderSide(color: MinePalette.edge))
            : null,
      ),
      child: Row(
        children: [
          _RankBox(rank: entry.rank),
          const SizedBox(width: AppSpace.md),
          MineAvatar(name: name, imageUrl: entry.avatarUrl),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MineNameWithLevel(name: name, level: entry.currentLevel),
                const SizedBox(height: AppSpace.hair),
                Row(
                  children: [
                    if (handle != null && handle.isNotEmpty)
                      Flexible(
                        child: Text(
                          '@$handle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(MinePalette.muted),
                        ),
                      ),
                    if (entry.isMiningNow) ...[
                      const SizedBox(width: AppSpace.sm),
                      Icon(
                        Icons.bolt_rounded,
                        size: AppIcon.xs,
                        color: MinePalette.accentSoft,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Flexible(
                        child: Text(
                          'mining now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(MinePalette.accentSoft),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Text(
            MineFormat.points(entry.claimedTotalPoints),
            style: AppText.label(MinePalette.text, weight: AppText.bold)
                .merge(AppText.tabular),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// The old board's rank square: amber-tinted for the top three.
class _RankBox extends StatelessWidget {
  const _RankBox({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final top = rank <= 3;
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      alignment: Alignment.center,
      decoration: top
          ? appTintDecoration(MinePalette.amber, bordered: true)
          : BoxDecoration(
              color: MinePalette.raised.withValues(alpha: 0.5),
              borderRadius: AppRadius.sm,
              border: Border.all(color: MinePalette.edge),
            ),
      child: Text(
        '$rank',
        style: AppText.label(mineRankColor(rank), weight: AppText.bold)
            .merge(AppText.tabular),
      ),
    );
  }
}
