import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_card_item.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_list_item.dart';
import 'package:blocnet/features/levels/presentation/widgets/tier_section_header.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:flutter/material.dart';

typedef LevelTapCallback = void Function(UserLevelModel level);

/// One tier block: header plus its levels, rendered as stacked rows
/// ([FeedViewMode.list]) or a three-up tile grid ([FeedViewMode.card]).
class TierSection extends StatelessWidget {
  const TierSection({
    super.key,
    required this.section,
    required this.currentLevelNumber,
    required this.mode,
    required this.onLevelTap,
  });

  final LevelTierSection section;
  final int currentLevelNumber;
  final FeedViewMode mode;
  final LevelTapCallback onLevelTap;

  static const double _tileGap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TierSectionHeader(
          section: section,
          currentLevelNumber: currentLevelNumber,
        ),
        if (mode == FeedViewMode.list) _buildList() else _buildTiles(),
      ],
    );
  }

  Widget _buildList() {
    final levels = section.levels;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: section.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < levels.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 3,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
            LevelListItem(
              level: levels[i],
              isCurrent: levels[i].level == currentLevelNumber,
              isLocked: levels[i].level > currentLevelNumber,
              tierColor: section.color,
              onTap: () => onLevelTap(levels[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTiles() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = LevelTier.levelsPerTier;
        final width =
            (constraints.maxWidth - _tileGap * (columns - 1)) / columns;
        return Wrap(
          spacing: _tileGap,
          runSpacing: _tileGap,
          children: [
            for (final level in section.levels)
              SizedBox(
                width: width,
                child: LevelCardItem(
                  level: level,
                  isCurrent: level.level == currentLevelNumber,
                  isLocked: level.level > currentLevelNumber,
                  tierColor: section.color,
                  onTap: () => onLevelTap(level),
                ),
              ),
          ],
        );
      },
    );
  }
}
