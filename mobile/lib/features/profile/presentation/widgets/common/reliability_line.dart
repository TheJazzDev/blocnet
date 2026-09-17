import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/profile/domain/reliability_summary.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_pill.dart';
import 'package:flutter/material.dart';

/// `[RELIABLE] 4 of 5 gems current` — the compact reliability line.
class ReliabilityLine extends StatelessWidget {
  const ReliabilityLine({super.key, required this.summary});

  final ReliabilitySummary summary;

  static Color colorFor(StandingTone tone) => switch (tone) {
        StandingTone.reliable => HubTone.accent,
        StandingTone.slipping => HubTone.quiet,
        StandingTone.unscored => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfilePill(
          label: summary.standing,
          color: colorFor(summary.tone),
        ),
        AppSpace.wGapSm,
        Flexible(
          child: Text(
            summary.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(AppColors.textMuted, weight: AppText.regular),
          ),
        ),
      ],
    );
  }
}
