import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:flutter/material.dart';

class UserNameWithLevelIcon extends StatelessWidget {
  const UserNameWithLevelIcon({
    super.key,
    required this.name,
    required this.textStyle,
    this.currentLevel,
    this.levelBadgeSize = LevelBadgeSize.small,
    this.iconSpacing = 6,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String name;
  final TextStyle textStyle;
  final UserLevelModel? currentLevel;
  final LevelBadgeSize levelBadgeSize;
  final double iconSpacing;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentLevel != null) ...[
          LevelBadgeIcon(
            level: currentLevel!,
            size: levelBadgeSize,
          ),
          SizedBox(width: iconSpacing),
        ],
        Flexible(
          child: Text(
            name,
            maxLines: maxLines,
            overflow: overflow,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
