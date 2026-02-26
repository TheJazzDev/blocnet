import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.radius,
    required this.imageUrl,
    required this.fallback,
    this.backgroundColor = AppColors.bgElevated,
    this.fit = BoxFit.cover,
  });

  final double radius;
  final String? imageUrl;
  final Widget fallback;
  final Color backgroundColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final normalized = imageUrl?.trim() ?? '';
    final hasImage = normalized.isNotEmpty;
    final size = radius * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              normalized,
              fit: fit,
              errorBuilder: (_, __, ___) => Center(child: fallback),
            )
          : Center(child: fallback),
    );
  }
}
