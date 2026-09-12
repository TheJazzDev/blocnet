import 'package:blocnet/app/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
          ? CachedNetworkImage(
              imageUrl: normalized,
              fit: fit,
              // Decode at the size actually drawn. Without this a large upload
              // is decoded at full resolution into memory to fill a tiny
              // circle, and that decode lands on the UI isolate mid-scroll.
              memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              memCacheHeight: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              placeholder: (_, __) => Center(child: fallback),
              errorWidget: (_, __, ___) => Center(child: fallback),
            )
          : Center(child: fallback),
    );
  }
}
