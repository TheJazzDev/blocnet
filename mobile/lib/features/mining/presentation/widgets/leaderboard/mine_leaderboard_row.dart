import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_member_parts.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:flutter/material.dart';

/// Gold, silver and bronze for ranks 1–3 only.
Color mineRankColor(int rank) => switch (rank) {
      1 => MinePalette.gold,
      2 => MinePalette.silver,
      3 => MinePalette.bronze,
      _ => MinePalette.caption,
    };

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
            ? const Border(bottom: BorderSide(color: MinePalette.rowHairline))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.right,
              style: AppText.label(
                mineRankColor(entry.rank),
                weight: AppText.bold,
              ).merge(AppText.tabular),
            ),
          ),
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
                          style: AppText.label(MinePalette.dim),
                        ),
                      ),
                    if (entry.isMiningNow) ...[
                      const SizedBox(width: AppSpace.sm),
                      const Icon(Icons.bolt_rounded,
                          size: AppIcon.xs, color: MinePalette.miningNow),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'mining now',
                        style: AppText.label(MinePalette.miningNow),
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
            style: AppText.body(MinePalette.body, weight: AppText.semibold)
                .merge(AppText.tabular),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
