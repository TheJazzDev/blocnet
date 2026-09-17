import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/tier_level_badge.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// Display name, else `@handle`, else a neutral fallback.
String mineMemberName(String? displayName, String? username) {
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final handle = username?.trim();
  if (handle != null && handle.isNotEmpty) return '@$handle';
  return 'Member';
}

/// 36 px avatar with two-letter initials as the fallback.
class MineAvatar extends StatelessWidget {
  const MineAvatar({super.key, required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;

  static String initials(String name) {
    final clean = name.replaceAll('@', '').trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length < 2 ? 1 : 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      radius: 18,
      imageUrl: imageUrl,
      backgroundColor: MinePalette.raised,
      fallback: Text(
        initials(name),
        style: AppText.label(MinePalette.text, weight: AppText.bold),
      ),
    );
  }
}

/// Name with the tier-shaped level badge beside it.
class MineNameWithLevel extends StatelessWidget {
  const MineNameWithLevel({
    super.key,
    required this.name,
    required this.level,
  });

  final String name;
  final UserLevelModel? level;

  @override
  Widget build(BuildContext context) {
    final number = level?.level ?? 0;
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(MinePalette.text, weight: AppText.bold),
          ),
        ),
        if (number > 0) ...[
          const SizedBox(width: AppSpace.sm),
          TierLevelBadge(level: number),
        ],
      ],
    );
  }
}
