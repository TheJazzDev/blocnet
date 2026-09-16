import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/domain/chain_style.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/tier_level_badge.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// Who the Hub belongs to, as the design's identity row states it.
@immutable
class HubIdentity {
  const HubIdentity({
    required this.name,
    this.handle,
    this.avatarUrl,
    this.level,
    this.levelName,
  });

  final String name;
  final String? handle;
  final String? avatarUrl;
  final int? level;
  final String? levelName;

  /// `@jazzdev · Ruby · Pioneer`, dropping what is unknown.
  String get subtitle {
    final lvl = level;
    return [
      if (handle != null && handle!.isNotEmpty) '@$handle',
      if (lvl != null && lvl > 0) LevelTier.forLevel(lvl).name,
      if (levelName != null && levelName!.isNotEmpty) levelName!,
    ].join(' · ');
  }
}

/// Avatar 44 · name · tier badge · `HUNTER`, then the handle line.
class HubIdentityRow extends StatelessWidget {
  const HubIdentityRow({
    super.key,
    required this.identity,
    this.bottomPadding = 16,
  });

  final HubIdentity identity;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final level = identity.level;
    final subtitle = identity.subtitle;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
      child: Row(
        children: [
          AppAvatar(
            radius: 22,
            imageUrl: identity.avatarUrl,
            fallback: _Initials(name: identity.name),
            backgroundColor: AppColors.hunterFill,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        identity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HubType.lead(AppColors.textPrimary),
                      ),
                    ),
                    if (level != null && level > 0) ...[
                      const SizedBox(width: 6),
                      TierLevelBadge(level: level),
                    ],
                    const SizedBox(width: 6),
                    HubPill(
                      label: 'Hunter',
                      color: AppColors.hunterAccent,
                      background: AppColors.chainIce.withValues(alpha: 0.14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.meta(AppColors.zincDim),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.hunterFill, AppColors.hunterDeep],
        ),
      ),
      child: Text(
        gemMonogram(name),
        style: AppTypography.custom(
          size: 15,
          weight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
