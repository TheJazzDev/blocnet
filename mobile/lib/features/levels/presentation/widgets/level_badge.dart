import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge_artwork.dart';
import 'package:flutter/material.dart';

export 'package:blocnet/features/levels/presentation/widgets/level_badge_artwork.dart'
    show LevelBadgeArtwork;

/// A reusable level badge that shows a user's level artwork, optionally
/// followed by the level number and name.
///
/// Used in comments, posts, profiles and anywhere a level needs to be shown.
/// Artwork resolution lives in [LevelBadgeArtwork].
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.small,
    this.showName = false,
    this.showLevelNumber = true,
  });

  final UserLevelModel level;
  final LevelBadgeSize size;
  final bool showName;
  final bool showLevelNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LevelBadgeArtwork(level: level, size: size.iconSize),
        if (showLevelNumber || showName) ...[
          const SizedBox(width: AppSpace.xs),
          Flexible(child: _buildLevelText()),
        ],
      ],
    );
  }

  Widget _buildLevelText() {
    final parts = <String>[
      if (showLevelNumber) 'Level ${level.level}',
      if (showName) level.name,
    ];

    return Text(
      parts.join(' • '),
      style: TextStyle(
        fontSize: size.fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Level badge size options.
enum LevelBadgeSize {
  /// 16px - for very compact spaces.
  tiny(iconSize: 16, fontSize: 10),

  /// 20px - for comments, inline text.
  small(iconSize: 20, fontSize: 11),

  /// 32px - for cards, list items.
  medium(iconSize: 32, fontSize: 13),

  /// 48px - for profile headers.
  large(iconSize: 48, fontSize: 15),

  /// 64px - for dedicated level displays.
  extraLarge(iconSize: 64, fontSize: 17);

  const LevelBadgeSize({required this.iconSize, required this.fontSize});

  final double iconSize;
  final double fontSize;
}

/// A compact level badge that only shows the artwork with a tooltip.
class LevelBadgeIcon extends StatelessWidget {
  const LevelBadgeIcon({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.small,
  });

  final UserLevelModel level;
  final LevelBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Level ${level.level} • ${level.name}',
      child: LevelBadge(
        level: level,
        size: size,
        showName: false,
        showLevelNumber: false,
      ),
    );
  }
}

/// A full level badge with level number and name.
class LevelBadgeFull extends StatelessWidget {
  const LevelBadgeFull({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.medium,
  });

  final UserLevelModel level;
  final LevelBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return LevelBadge(
      level: level,
      size: size,
      showName: true,
      showLevelNumber: true,
    );
  }
}
