import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One reported quiet gem in the moderator queue. Same anatomy as the appeal
/// card: a tinted header, the facts, and the action.
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
    final tone = AppColors.warning500;
    final reportLabel =
        gem.openReports == 1 ? '1 REPORT' : '${gem.openReports} REPORTS';

    return AppSurface.flush(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: AppSpace.hair),
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(AppRadius.smValue),
                  ),
                  child: Text(
                    reportLabel,
                    style: AppTypography.custom(
                      color: Colors.black,
                      size: AppText.captionSize,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    gem.projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Since ${DateFormat('MMM d').format(gem.firstReportedAt.toLocal())}',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FactsLine(gem: gem),
                const SizedBox(height: AppSpace.md),
                Text(
                  gem.hunters.length == 1 ? 'Hunter' : 'Hunters',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                if (gem.hunters.isEmpty)
                  Text(
                    'No owner on record',
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.captionSize,
                      weight: FontWeight.w400,
                    ),
                  )
                else
                  for (final hunter in gem.hunters) _HunterRow(hunter: hunter),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isResolving ? null : onResolve,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.moderationAccent,
                      side: const BorderSide(color: AppColors.moderationAccent),
                      minimumSize: const Size.fromHeight(44),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpace.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.smValue),
                      ),
                    ),
                    child: isResolving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Resolve',
                            style: AppTypography.custom(
                              color: AppColors.moderationAccent,
                              size: AppText.labelSize,
                              weight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsLine extends StatelessWidget {
  const _FactsLine({required this.gem});

  final InactiveGemReport gem;

  @override
  Widget build(BuildContext context) {
    final quiet = gem.daysQuiet == 1 ? '1 day' : '${gem.daysQuiet} days';
    final facts = <String>[
      'Quiet $quiet',
      if (gem.membersWaiting > 0)
        gem.membersWaiting == 1
            ? '1 member waiting'
            : '${gem.membersWaiting} members waiting',
      if (gem.primaryTag.isNotEmpty) gem.primaryTag,
      if (gem.projectStatus != 'active') gem.projectStatus,
    ];

    return Row(
      children: [
        Icon(Icons.schedule_rounded,
            size: AppIcon.sm, color: AppColors.textMuted),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            facts.join(' · '),
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.captionSize,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HunterRow extends StatelessWidget {
  const _HunterRow({required this.hunter});

  final InactiveGemHunter hunter;

  Color get _tone {
    switch (hunter.standing) {
      case ReliabilityStanding.reliable:
        return AppColors.successColor;
      case ReliabilityStanding.slipping:
        return AppColors.warning500;
      case ReliabilityStanding.quiet:
        return AppColors.error500;
      case ReliabilityStanding.newHunter:
      case ReliabilityStanding.unknown:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverage = hunter.coverage;
    final standing = coverage == null
        ? hunter.standing.label
        : '${hunter.standing.label} · ${(coverage * 100).round()}% current';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Icon(Icons.person_outline,
              size: AppIcon.sm, color: AppColors.textMuted),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              hunter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm, vertical: AppSpace.hair),
            decoration: BoxDecoration(
              color: _tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.smValue),
            ),
            child: Text(
              standing,
              style: AppTypography.custom(
                color: _tone,
                size: AppText.captionSize,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
