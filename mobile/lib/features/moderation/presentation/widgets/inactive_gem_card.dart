import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_button.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One reported quiet gem in the moderator queue: the report count and
/// date, the gem and its facts, its hunters with their standing, Resolve.
class InactiveGemCard extends StatelessWidget {
  const InactiveGemCard({
    required this.gem,
    required this.onResolve,
    this.isResolving = false,
    super.key,
  });

  final InactiveGemReport gem;
  final VoidCallback onResolve;
  final bool isResolving;

  @override
  Widget build(BuildContext context) {
    final reportLabel =
        gem.openReports == 1 ? '1 report' : '${gem.openReports} reports';

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ModPill(label: reportLabel, color: AppColors.tagAirdrop),
              const Spacer(),
              Text(
                'Since ${DateFormat('MMM d').format(gem.firstReportedAt.toLocal())}',
                style: ModText.meta(AppColors.textFaint),
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(
            gem.projectName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ModText.rowTitle(AppColors.textPrimary),
          ),
          AppSpace.gapXs,
          Text(_facts(), style: ModText.meta(AppColors.textMuted)),
          AppSpace.gapMd,
          const ModHairline(),
          AppSpace.gapMd,
          Text(
            (gem.hunters.length == 1 ? 'Hunter' : 'Hunters').toUpperCase(),
            style: ModText.caps(AppColors.textFaint),
          ),
          AppSpace.gapSm,
          if (gem.hunters.isEmpty)
            Text(
              'No owner on record',
              style: ModText.meta(AppColors.textSecondary),
            )
          else
            for (final hunter in gem.hunters) _HunterRow(hunter: hunter),
          AppSpace.gapMd,
          SizedBox(
            width: double.infinity,
            child: ModButton(
              label: 'Resolve',
              tone: ModButtonTone.filled,
              busy: isResolving,
              onTap: onResolve,
            ),
          ),
        ],
      ),
    );
  }

  String _facts() {
    final quiet = gem.daysQuiet == 1 ? '1 day' : '${gem.daysQuiet} days';
    return <String>[
      'Quiet $quiet',
      if (gem.membersWaiting > 0)
        gem.membersWaiting == 1
            ? '1 member waiting'
            : '${gem.membersWaiting} members waiting',
      if (gem.primaryTag.isNotEmpty) gem.primaryTag,
      if (gem.projectStatus != 'active') gem.projectStatus,
    ].join(' · ');
  }
}

class _HunterRow extends StatelessWidget {
  const _HunterRow({required this.hunter});

  final InactiveGemHunter hunter;

  Color get _tone => switch (hunter.standing) {
        ReliabilityStanding.reliable => AppColors.successColor,
        ReliabilityStanding.slipping => AppColors.warning500,
        ReliabilityStanding.quiet => AppColors.tagAirdrop,
        ReliabilityStanding.newHunter ||
        ReliabilityStanding.unknown =>
          AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final coverage = hunter.coverage;
    final standing = coverage == null
        ? hunter.standing.label
        : '${hunter.standing.label} · ${(coverage * 100).round()}% current';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: AppIcon.sm,
            color: AppColors.textMuted,
          ),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              hunter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                AppColors.textPrimary,
                weight: AppText.semibold,
              ),
            ),
          ),
          AppSpace.wGapSm,
          ModPill(label: standing, color: _tone, uppercase: false),
        ],
      ),
    );
  }
}
