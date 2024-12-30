import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    this.onPressed,
    this.svgAsset,
    this.iconData,
    this.svgDimentions,
    super.key,
  }) : assert(svgAsset != null || iconData != null,
            'Either svgAsset or iconData must be provided');

  final VoidCallback? onPressed;
  final String? svgAsset;
  final IconData? iconData;
  final double? svgDimentions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.darkGrey100,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: svgAsset != null
            ? SvgPicture.asset(
                svgAsset!,
                width: svgDimentions,
                height: svgDimentions,
              )
            : Icon(iconData, size: 26, color: AppColors.darkGrey500),
        onPressed: onPressed,
      ),
    );
  }
}
