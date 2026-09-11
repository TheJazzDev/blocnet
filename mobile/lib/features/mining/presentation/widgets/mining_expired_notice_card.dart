import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/mining_expiry_copy.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:flutter/material.dart';

/// Explains a cycle the user lost by not claiming it in time.
///
/// Shown when the snapshot's `lastExpiredCycle` is still the most recent thing
/// that happened on the account — i.e. the forfeit happened at or after the
/// current cycle began, or there is no cycle running yet. Once the user
/// completes and claims a later cycle the notice stops applying on its own.
class MiningExpiredNoticeCard extends StatelessWidget {
  const MiningExpiredNoticeCard({
    super.key,
    required this.cycle,
    required this.claimWindowHours,
    this.onDismiss,
  });

  final MiningExpiredCycle cycle;
  final int claimWindowHours;
  final VoidCallback? onDismiss;

  /// True while [cycle] is worth telling the user about. A forfeit that
  /// predates the running cycle is history, not news.
  static bool isCurrent(MiningSnapshot? snapshot) {
    final cycle = snapshot?.lastExpiredCycle;
    if (cycle == null) return false;

    final sessionStart = snapshot?.session.startsAt;
    if (sessionStart == null) return true;

    final expiredAt = cycle.expiredAt;
    if (expiredAt == null) return false;

    // The backend opens the replacement cycle at the moment of expiry, so
    // allow a small tolerance for the two timestamps not being identical.
    return !expiredAt
        .toUtc()
        .isBefore(sessionStart.toUtc().subtract(const Duration(minutes: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.warning500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hourglass_disabled_rounded,
            color: accent,
            size: AppIcon.md,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MiningExpiryCopy.noticeTitle,
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  MiningExpiryCopy.lastExpiredCycle(
                    cycle,
                    claimWindowHours: claimWindowHours,
                  ),
                  style: AppTypography.custom(
                    size: AppText.captionSize,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  GestureDetector(
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xs,
                      ),
                      child: Text(
                        'Got it',
                        style: AppTypography.custom(
                          size: AppText.captionSize,
                          weight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
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
