import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_parts.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_view.dart';
import 'package:flutter/material.dart';

/// The hero's single primary action, or null when there is none to offer —
/// an idle hero while mining is paused has no Start and nothing to claim.
MiningActionState? resolveMiningAction({
  required MiningHeroView view,
  required MiningSessionModel session,
  required DateTime now,
  required bool isStarting,
  required bool isClaiming,
  required VoidCallback onStart,
  required VoidCallback onClaim,
}) {
  final busy = isStarting || isClaiming;

  if (view.canClaim) {
    return MiningActionState(
      label: 'Claim Rewards',
      color: AppColors.successColor,
      textColor: Colors.black,
      onPressed: busy ? null : onClaim,
      isLoading: isClaiming,
    );
  }

  if (view.canStart) {
    return MiningActionState(
      label: 'Start Mining',
      color: AppColors.primary500,
      textColor: Colors.black,
      onPressed: busy ? null : onStart,
      isLoading: isStarting,
    );
  }

  if (!view.isLive) return null;

  final countdown = MiningHeroView.formatCountdown(session.endsAt, now);
  final label = countdown == null
      ? 'Claim Locked'
      : view.phase == MiningHeroPhase.finishing
          // Server time hit the end but the server has not marked the cycle
          // claimable yet. Never label this "Claim" — it would fail.
          ? 'Wrapping up this cycle...'
          : 'Claim in $countdown';
  return MiningActionState(
    label: label,
    color: AppColors.bgElevated,
    textColor: AppColors.textMuted,
    onPressed: null,
    isLoading: false,
    showLockIcon: true,
  );
}

/// Two soft radial glows behind the hero.
class MiningHeroGlows extends StatelessWidget {
  const MiningHeroGlows({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -44,
              top: -26,
              child: _Glow(
                size: 180,
                color: AppColors.primary500.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              left: -34,
              bottom: -30,
              child: _Glow(
                size: 150,
                color: AppColors.primary400.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
