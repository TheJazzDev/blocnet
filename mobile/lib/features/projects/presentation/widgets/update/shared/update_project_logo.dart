import 'dart:math';
import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class UpdateProjectLogo extends StatelessWidget {
  const UpdateProjectLogo({required this.logoUrl, required this.size, super.key});

  final String logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: size == 40 ? 2 : 3,
          left: size == 40 ? 5 : 7,
          child: Transform.rotate(
            angle: 6 * pi / 180,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.darkGrey300,
                borderRadius: BorderRadius.circular(size == 40 ? 10 : 15),
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(size == 40 ? 10 : 15),
          child: logoUrl.trim().isEmpty
              ? Container(
                  width: size,
                  height: size,
                  color: AppColors.darkGrey200,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.layers,
                    color: AppColors.darkGrey600,
                    size: size / 2.8,
                  ),
                )
              : Image.network(
                  logoUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: size,
                    height: size,
                    color: AppColors.darkGrey200,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.layers,
                      color: AppColors.darkGrey600,
                      size: size / 2.8,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
