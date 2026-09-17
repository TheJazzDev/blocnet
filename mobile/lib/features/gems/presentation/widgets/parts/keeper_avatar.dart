import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// A hunter's photo, or their initials.
class KeeperAvatar extends StatelessWidget {
  const KeeperAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.radius = 12,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      radius: radius,
      imageUrl: imageUrl,
      fallback: Text(
        _initials(name),
        style: AppText.caption(AppColors.textSecondary, weight: AppText.bold),
      ),
    );
  }

  static String _initials(String name) {
    final words = name
        .replaceAll('@', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
