import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
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
      padding: EdgeInsets.fromLTRB(
        HubInsets.gutter,
        AppSpace.md,
        HubInsets.gutter,
        bottomPadding,
      ),
      child: Row(
        children: [
          _Avatar(identity: identity),
          AppSpace.wGapMd,
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
                    const HubPill(label: 'Hunter', color: HubTone.hunterRole),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.meta(AppColors.textFaint),
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

/// The old profile avatar: a dark disc inside an accent ring.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.identity});

  final HubIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.hair),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: HubTone.accent, width: 1.5),
      ),
      child: AppAvatar(
        radius: 20,
        imageUrl: identity.avatarUrl,
        fallback: Text(
          gemMonogram(identity.name),
          style: AppText.body(HubTone.accent, weight: AppText.bold)
              .copyWith(height: 1),
        ),
      ),
    );
  }
}
