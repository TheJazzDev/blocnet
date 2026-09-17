import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:flutter/material.dart';

/// A small level badge in its tier's silhouette, carrying the level number.
///
/// The design's `.bdg`: Iron is a circle, Jade a hexagon, Amethyst a shield,
/// Gold an octagon, Ruby a seal. Unlike the full badge artwork this reads at
/// 18px beside a name.
class TierLevelBadge extends StatelessWidget {
  const TierLevelBadge({super.key, required this.level, this.size = 18});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tier = LevelTier.forLevel(level);
    final number = Text(
      '$level',
      style: AppTypography.custom(
        size: size * 0.5,
        weight: FontWeight.w800,
        color: AppColors.bgBase,
        height: 1,
      ),
    );
    final points = tierBadgeOutline(tier);
    return Semantics(
      label: 'Level $level ${tier.name}',
      child: SizedBox(
        width: size,
        height: size,
        child: points == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tier.fallbackColor,
                ),
                child: Center(child: number),
              )
            : ClipPath(
                clipper: _PolygonClipper(points),
                child: ColoredBox(
                  color: tier.fallbackColor,
                  child: Center(child: number),
                ),
              ),
      ),
    );
  }
}

/// The tier's outline as fractions of the badge box, or null for a circle.
/// Taken from the design's `clip-path` polygons.
List<Offset>? tierBadgeOutline(LevelTier tier) {
  switch (tier.index) {
    case 1: // Jade — hexagon
      return const [
        Offset(.5, 0), Offset(.93, .25), Offset(.93, .75), //
        Offset(.5, 1), Offset(.07, .75), Offset(.07, .25),
      ];
    case 2: // Amethyst — shield
      return const [
        Offset(.5, 0), Offset(1, .04), Offset(1, .58), //
        Offset(.5, 1), Offset(0, .58), Offset(0, .04),
      ];
    case 3: // Gold — octagon
      return const [
        Offset(.3, 0), Offset(.7, 0), Offset(1, .3), Offset(1, .7), //
        Offset(.7, 1), Offset(.3, 1), Offset(0, .7), Offset(0, .3),
      ];
    case 4: // Ruby — seal
      return const [
        Offset(.5, 0), Offset(.715, .128), Offset(.933, .25), //
        Offset(.93, .5), Offset(.933, .75), Offset(.715, .872),
        Offset(.5, 1), Offset(.285, .872), Offset(.067, .75),
        Offset(.07, .5), Offset(.067, .25), Offset(.285, .128),
      ];
    default: // Iron — circle
      return null;
  }
}

class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) {
    return Path()
      ..addPolygon(
        [for (final p in points) Offset(p.dx * size.width, p.dy * size.height)],
        true,
      );
  }

  @override
  bool shouldReclip(_PolygonClipper oldClipper) => oldClipper.points != points;
}
