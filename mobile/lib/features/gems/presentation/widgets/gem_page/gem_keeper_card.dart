import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/keeper_avatar.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/standing_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// Who keeps the gem: name, standing, and the numbers behind the standing.
class GemKeeperCard extends StatelessWidget {
  const GemKeeperCard({super.key, required this.keeper, required this.onOpen});

  final GemKeeper keeper;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (keeper.coverageLine != null) ('Coverage', keeper.coverageLine!),
      if (_cadence != null) ('Posts', _cadence!),
      if (_response != null) ('Answers asks', _response!),
    ];

    return HomePanel(
      key: const ValueKey('gem-keeper-card'),
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomePanelHeader(
              icon: Icons.shield_outlined,
              label: 'KEPT BY',
              iconColor: AppColors.primary500,
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: AppIcon.md,
                color: AppColors.textFaint,
              ),
            ),
            AppSpace.gapMd,
            Row(
              children: [
                KeeperAvatar(
                  name: keeper.name,
                  imageUrl: keeper.avatarUrl,
                  radius: 18,
                ),
                AppSpace.wGapMd,
                Expanded(child: _Name(keeper: keeper)),
                AppSpace.wGapSm,
                StandingPill(standing: keeper.standing),
              ],
            ),
            for (final (label, value) in rows) _MetricRow(label, value),
          ],
        ),
      ),
    );
  }

  String? get _cadence {
    final days = keeper.cadenceDays;
    if (days == null) return null;
    final whole = days.round();
    if (whole <= 1) return 'About daily';
    return 'About every $whole days';
  }

  String? get _response {
    final asked = keeper.responseAsked;
    final answered = keeper.responseAnswered;
    if (asked != null && answered != null && asked > 0) {
      return '$answered of $asked';
    }
    final share = keeper.response;
    return share == null ? null : '${(share * 100).round()}%';
  }
}

class _Name extends StatelessWidget {
  const _Name({required this.keeper});

  final GemKeeper keeper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                keeper.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HubType.rowTitle(AppColors.textPrimary),
              ),
            ),
            if (keeper.level != null) ...[
              AppSpace.wGapXs,
              LevelBadgeIcon(level: keeper.level!, size: LevelBadgeSize.tiny),
            ],
          ],
        ),
        if (keeper.handle != null)
          Text(
            keeper.handle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HubType.meta(AppColors.textFaint),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.md),
      padding: const EdgeInsets.only(top: AppSpace.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Text(label, style: HubType.meta(AppColors.textMuted)),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HubType.meta(
                AppColors.textPrimary,
                weight: AppText.semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
