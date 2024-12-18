import 'dart:math';
import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';

class PostProjectLogo extends StatelessWidget {
  const PostProjectLogo({required this.logoUrl, required this.size, super.key});

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
          child: Image.network(
            logoUrl,
            width: size,
            height: size,
          ),
        ),
      ],
    );
  }
}
