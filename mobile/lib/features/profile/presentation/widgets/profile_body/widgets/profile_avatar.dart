import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

/// A plain round avatar with a hairline border and an initial fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.size = 56,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final initial = Center(
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: AppText.headline(AppColors.primary400),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgElevated,
        border: Border.all(color: AppColors.borderMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? initial
          : AppNetworkImage(url: url, fit: BoxFit.cover, fallback: initial),
    );
  }
}
