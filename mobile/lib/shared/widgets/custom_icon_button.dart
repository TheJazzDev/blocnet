import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    this.onPressed,
    this.svgAsset,
    this.iconData,
    this.svgDimentions,
    super.key,
  }) : assert(
         svgAsset != null || iconData != null,
         'Either svgAsset or iconData must be provided',
       );

  final VoidCallback? onPressed;
  final String? svgAsset;
  final IconData? iconData;
  final double? svgDimentions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.bgElevated,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: svgAsset != null
            ? SvgPicture.asset(
                svgAsset!,
                width: svgDimentions,
                height: svgDimentions,
              )
            : Icon(iconData, size: AppIcon.lg, color: AppColors.textMuted),
        onPressed: onPressed,
      ),
    );
  }
}
