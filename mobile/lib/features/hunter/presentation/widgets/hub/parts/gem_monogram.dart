import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/domain/chain_style.dart';
import 'package:flutter/material.dart';

/// Size steps for a gem's monogram (design: 32 / 40 / 52).
enum GemMonogramSize {
  small(32, 8, 11),
  medium(40, 12, 13),
  large(52, 14, 17);

  const GemMonogramSize(this.extent, this.radius, this.fontSize);

  final double extent;
  final double radius;
  final double fontSize;
}

/// Two letters on a gradient of the gem's chain hue. Projects have no logo
/// column, so this stands in for one.
class GemMonogram extends StatelessWidget {
  const GemMonogram({
    super.key,
    required this.name,
    required this.tag,
    this.size = GemMonogramSize.medium,
  });

  final String name;
  final String tag;
  final GemMonogramSize size;

  @override
  Widget build(BuildContext context) {
    final style = ChainStyle.forTag(tag);
    return Container(
      width: size.extent,
      height: size.extent,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
      ),
      child: Text(
        gemMonogram(name),
        style: AppTypography.custom(
          size: size.fontSize,
          weight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
