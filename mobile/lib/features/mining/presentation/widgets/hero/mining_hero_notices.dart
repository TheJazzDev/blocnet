import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// First load in flight. Shows no numbers: until the server answers there is
/// no rate, balance or cycle length worth printing.
class MiningHeroLoading extends StatelessWidget {
  const MiningHeroLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return _HeroNoticeFrame(
      child: Column(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: AppColors.primary500,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Checking your mining status...',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              size: AppText.labelSize,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// First load failed. Replaces the hero rather than showing a default idle
/// card that would offer Start on data that never arrived (F-53).
class MiningHeroError extends StatelessWidget {
  const MiningHeroError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HeroNoticeFrame(
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: AppIcon.lg,
            color: AppColors.error500,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            "Couldn't load your mining status",
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              size: AppText.bodySize,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              size: AppText.labelSize,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: AppIcon.sm),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary400,
                side: BorderSide(
                  color: AppColors.primary500.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgValue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `config.enabled` is false. Says so plainly, and whether a finished cycle
/// can still be collected.
class MiningPausedNotice extends StatelessWidget {
  const MiningPausedNotice({super.key, required this.canClaim});

  final bool canClaim;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.warning500;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pause_circle_rounded, size: AppIcon.md, color: accent),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mining is paused',
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  canClaim
                      ? 'New cycles are off for now. Your finished cycle can '
                          'still be claimed.'
                      : 'New cycles are off for now. Anything you already '
                          'mined is safe.',
                  style: AppTypography.custom(
                    size: AppText.captionSize,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
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

class _HeroNoticeFrame extends StatelessWidget {
  const _HeroNoticeFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.xlValue),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}
