import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/chain_style.dart';
import 'package:flutter/material.dart';

/// Size steps for a gem's monogram.
enum GemMonogramSize {
  small(32, AppRadius.sm, AppText.labelSize),
  medium(40, AppRadius.md, AppText.bodySize),
  large(44, AppRadius.md, AppText.subtitleSize);

  const GemMonogramSize(this.extent, this.radius, this.fontSize);

  final double extent;
  final BorderRadius radius;
  final double fontSize;
}

/// Two letters in the gem's chain hue on a flat logo tile — the old
/// project list's logo box. Projects have no logo column, so this stands in
/// for one.
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
        color: AppColors.bgElevated,
        borderRadius: size.radius,
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Text(
        gemMonogram(name),
        style: TextStyle(
          fontSize: size.fontSize,
          fontWeight: AppText.bold,
          color: style.label.isEmpty ? AppColors.textSecondary : style.color,
          height: 1,
        ),
      ),
    );
  }
}
