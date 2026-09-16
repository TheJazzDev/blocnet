import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_parts.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:flutter/material.dart';

String _formatDecimal(num value) => formatGroupedNumber(value, maxDecimals: 2);

/// Hourly rate, cycle progress and what this cycle has mined so far.
class MiningEarningPanel extends StatelessWidget {
  const MiningEarningPanel({
    super.key,
    required this.snapshot,
    required this.cycleHours,
    required this.canClaim,
  });

  final MiningSnapshot snapshot;
  final int cycleHours;
  final bool canClaim;

  @override
  Widget build(BuildContext context) {
    final session = snapshot.session;
    final hourlyReward = session.hourlyRateNow;
    final progressPct = session.progressPct.clamp(0, 1).toDouble();
    final cycleMined =
        session.pointsMinedSoFar + session.currentHourEstimatedPoints;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xlValue),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'EARNING PER HOUR',
            style: AppTypography.custom(
              size: AppText.captionSize,
              weight: FontWeight.w700,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatDecimal(hourlyReward),
                style: AppTypography.custom(
                  size: AppText.displayXlSize,
                  weight: FontWeight.w800,
                  color: AppColors.primary400,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'BNP/h',
                style: AppTypography.custom(
                  size: AppText.subtitleSize,
                  weight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.fullValue),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progressPct,
              backgroundColor: AppColors.bgElevated,
              color: canClaim ? AppColors.successColor : AppColors.primary500,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${_formatDecimal(cycleMined)} BNP earned • Claim after ${cycleHours}h',
            style: AppTypography.custom(
              size: AppText.labelSize,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four tiles under the panel. "Mining Power TH/s" was invented client-side
/// (F-55); its slot shows the claim window, which is real and matters.
class MiningStatsGrid extends StatelessWidget {
  const MiningStatsGrid({super.key, required this.snapshot});

  final MiningSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final balance = snapshot.balance;
    final activeReferrals = snapshot.session.activeReferralsSnapshot;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MiningCompactStat(
                label: 'Claim window',
                value: '${snapshot.config.claimWindowHours}h',
                icon: Icons.timer_outlined,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: MiningCompactStat(
                label: 'Total Earned',
                value:
                    '${formatGroupedNumber(balance.lifetimeEarnedPoints, maxDecimals: 0)} BNP',
                icon: Icons.stars_rounded,
                color: AppColors.warning500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: MiningCompactStat(
                label: 'Claimed',
                value:
                    '${formatGroupedNumber(balance.claimedTotalPoints, maxDecimals: 0)} BNP',
                icon: Icons.check_circle_rounded,
                color: AppColors.successColor,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: MiningCompactStat(
                label: 'Referrals',
                value: '$activeReferrals active',
                icon: Icons.people_rounded,
                color: AppColors.teal400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
