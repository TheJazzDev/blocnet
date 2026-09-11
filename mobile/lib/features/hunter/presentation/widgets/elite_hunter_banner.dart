import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Elite Hunter Status — a target to reach, not a standard being missed.
///
/// The banner used to read "Maintain 85%+ success rate to keep Elite status"
/// above "Current quality rate: 0%", which tells a hunter on day one that they
/// have already lost something they never had. The copy now depends on where
/// the hunter actually is: not started, on the way, or holding it.
class EliteHunterBanner extends StatelessWidget {
  const EliteHunterBanner({
    super.key,
    required this.qualityRate,
    required this.hasSignals,
  });

  /// Share of this hunter's updates posted at medium or high priority.
  final int qualityRate;

  /// False until the hunter has posted their first update, when [qualityRate]
  /// is 0 only because there is nothing to measure.
  final bool hasSignals;

  /// The quality rate that unlocks Elite status.
  static const int targetRate = 85;

  bool get _isElite => hasSignals && qualityRate >= targetRate;

  String get _headline => _isElite ? 'Elite Hunter' : 'Elite Hunter Status';

  String get _goal => _isElite
      ? 'You hold Elite status. Keep your quality rate at $targetRate% or '
          'above to stay there.'
      : 'Elite status starts at a $targetRate% quality rate.';

  String get _progress {
    if (!hasSignals) {
      return 'Post your first update to start tracking your quality rate.';
    }
    if (_isElite) return 'Your quality rate: $qualityRate%';
    return 'Your quality rate so far: $qualityRate% of $targetRate%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpace.allLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.12),
            AppColors.primary500.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: AppIcon.xxl - AppSpace.sm,
            height: AppIcon.xxl - AppSpace.sm,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.15),
              borderRadius: AppRadius.md,
            ),
            child: Icon(
              _isElite
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_outlined,
              color: AppColors.primary400,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headline,
                  style: AppText.label(
                    AppColors.primary400,
                    weight: AppText.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(_goal, style: AppText.caption(AppColors.textMuted)),
                const SizedBox(height: AppSpace.hair),
                Text(_progress, style: AppText.caption(AppColors.textFaint)),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: AppIcon.md,
            color: AppColors.primary400.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
