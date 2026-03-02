import 'dart:async';
import 'dart:math' as math;

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

class MiningHeroCard extends StatefulWidget {
  const MiningHeroCard({
    super.key,
    required this.snapshot,
    required this.onStart,
    required this.onClaim,
    required this.isStarting,
    required this.isClaiming,
  });

  final MiningSnapshot? snapshot;
  final VoidCallback onStart;
  final VoidCallback onClaim;
  final bool isStarting;
  final bool isClaiming;

  @override
  State<MiningHeroCard> createState() => _MiningHeroCardState();
}

class _MiningHeroCardState extends State<MiningHeroCard>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _counterOrbitController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _counterOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _syncAnimationState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void didUpdateWidget(covariant MiningHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimationState();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _orbitController.dispose();
    _counterOrbitController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _syncAnimationState() {
    final isRunning = widget.snapshot?.session.isRunning == true;
    if (isRunning) {
      if (!_orbitController.isAnimating) _orbitController.repeat();
      if (!_counterOrbitController.isAnimating) {
        _counterOrbitController.repeat();
      }
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_waveController.isAnimating) _waveController.repeat();
      return;
    }

    _orbitController.stop();
    _counterOrbitController.stop();
    _pulseController.stop();
    _waveController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final session = snapshot?.session;
    final referral = snapshot?.referral;
    final balance = snapshot?.balance;
    final config = snapshot?.config;

    final busy = widget.isStarting || widget.isClaiming;
    final cycleHours =
        (session?.cycleHours ?? config?.cycleHours ?? 24).clamp(1, 168);
    final activeDirectReferrals = session?.activeReferralsSnapshot ??
        referral?.activeDirectReferrals ??
        0;
    final projectedCyclePoints = session?.projectedCyclePointsNow ??
        session?.effectivePointsPerCycle ??
        config?.basePointsPerCycle ??
        120;
    final hourlyReward = session?.hourlyRateNow ??
        (projectedCyclePoints / math.max(cycleHours, 1));
    final progressPct = (session?.progressPct ?? 0).clamp(0, 1).toDouble();
    final thisHourMined = session?.currentHourEstimatedPoints ?? 0.0;
    final cycleMinedDisplay = (session?.pointsMinedSoFar ?? 0) + thisHourMined;
    final miningPower = 10 + (activeDirectReferrals * 0.1);

    final canStart = session == null || session.isIdle;
    final canClaim = session?.isClaimable ?? false;
    final statusLabel = canClaim
        ? 'Claim Ready'
        : session?.isRunning == true
            ? 'Live'
            : 'Idle';
    final statusSubtext = _statusSubtext(session, _now);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -44,
          top: -26,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary500.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -34,
          bottom: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary400.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusSubtext,
                          style: AppTypography.custom(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusTag(
                    label: statusLabel,
                    color: canClaim
                        ? AppColors.successColor
                        : session?.isRunning == true
                            ? AppColors.primary500
                            : AppColors.textFaint,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _orbitController,
                    _counterOrbitController,
                    _pulseController,
                    _waveController,
                  ]),
                  builder: (context, _) => _MiningCoreVisual(
                    isRunning: session?.isRunning == true,
                    orbitValue: _orbitController.value,
                    counterOrbitValue: _counterOrbitController.value,
                    pulseValue: _pulseController.value,
                    waveValue: _waveController.value,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Main earning display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'EARNING PER HOUR',
                      style: AppTypography.custom(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.textFaint,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatDecimal(hourlyReward),
                          style: AppTypography.custom(
                            size: 42,
                            weight: FontWeight.w800,
                            color: AppColors.primary400,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BNP/h',
                          style: AppTypography.custom(
                            size: 16,
                            weight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progressPct,
                        backgroundColor: AppColors.bgElevated,
                        color: canClaim
                            ? AppColors.successColor
                            : AppColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDecimal(cycleMinedDisplay)} BNP earned • Claim after 24h',
                      style: AppTypography.custom(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _CompactStat(
                      label: 'Mining Power',
                      value:
                          '${formatGroupedNumber(miningPower, maxDecimals: 1, minDecimals: 1)} TH/s',
                      icon: Icons.speed_rounded,
                      color: AppColors.primary400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactStat(
                      label: 'Total Earned',
                      value:
                          '${formatGroupedNumber(balance?.lifetimeEarnedPoints ?? 0, maxDecimals: 0)} BNP',
                      icon: Icons.stars_rounded,
                      color: AppColors.warning500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _CompactStat(
                      label: 'Claimed',
                      value:
                          '${formatGroupedNumber(balance?.claimedTotalPoints ?? 0, maxDecimals: 0)} BNP',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactStat(
                      label: 'Referrals',
                      value: '$activeDirectReferrals active',
                      icon: Icons.people_rounded,
                      color: AppColors.teal400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (canStart)
                _MiningActionButton(
                  label: 'Start Mining',
                  color: AppColors.primary500,
                  textColor: Colors.black,
                  onPressed: busy ? null : widget.onStart,
                  isLoading: widget.isStarting,
                ),
              if (canStart && canClaim) const SizedBox(height: 10),
              if (canClaim)
                _MiningActionButton(
                  label: 'Claim Rewards',
                  color: AppColors.successColor,
                  textColor: Colors.black,
                  onPressed: busy ? null : widget.onClaim,
                  isLoading: widget.isClaiming,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusSubtext(MiningSessionModel? session, DateTime now) {
    if (session == null || session.isIdle) {
      return 'Start to begin your 24h cycle.';
    }
    if (session.isClaimable) {
      return 'Cycle complete. You can claim now.';
    }
    final remainingLabel = _formatRemaining(session.endsAt, now);
    return remainingLabel == null
        ? 'Mining in progress'
        : 'Claim unlocks in $remainingLabel';
  }

  String? _formatRemaining(DateTime? endsAt, DateTime now) {
    if (endsAt == null) return null;
    final left = endsAt.toUtc().difference(now.toUtc());
    if (left.isNegative) return '0m';

    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${math.max(minutes, 0)}m';
  }

  String _formatDecimal(num value) {
    return formatGroupedNumber(value, maxDecimals: 2);
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          size: 10,
          weight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgElevated.withValues(alpha: 0.5),
        border:
            Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.custom(
                    size: 10,
                    weight: FontWeight.w600,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.custom(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiningActionButton extends StatelessWidget {
  const _MiningActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.35),
          foregroundColor: textColor,
          disabledForegroundColor: textColor.withValues(alpha: 0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: AppTypography.custom(
                  size: 13,
                  weight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class _MiningCoreVisual extends StatelessWidget {
  const _MiningCoreVisual({
    required this.isRunning,
    required this.orbitValue,
    required this.counterOrbitValue,
    required this.pulseValue,
    required this.waveValue,
  });

  final bool isRunning;
  final double orbitValue;
  final double counterOrbitValue;
  final double pulseValue;
  final double waveValue;

  @override
  Widget build(BuildContext context) {
    final primary = isRunning ? AppColors.primary500 : AppColors.textFaint;
    final scale = isRunning ? 0.9 + (pulseValue * 0.22) : 1.0;
    final glowOpacity = isRunning ? 0.26 + (pulseValue * 0.22) : 0.09;
    final orbitAngle = orbitValue * 2 * math.pi;
    final counterAngle = (1 - counterOrbitValue) * 2 * math.pi;
    final wobble = isRunning ? math.sin(orbitAngle) * 0.14 : 0.0;

    return SizedBox(
      width: 208,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: glowOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.2),
              ),
            ),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary400.withValues(alpha: 0.16),
              ),
            ),
          ),
          _OrbitDot(
            angle: orbitAngle,
            radius: 78,
            color: primary,
            size: 11,
          ),
          _OrbitDot(
            angle: counterAngle,
            radius: 58,
            color:
                AppColors.primary300.withValues(alpha: isRunning ? 0.9 : 0.45),
            size: 8,
          ),
          Transform.rotate(
            angle: wobble,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgElevated,
                    AppColors.bgSurface,
                  ],
                ),
                border: Border.all(color: AppColors.borderMuted),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.24),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 38,
                color: primary,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: _SignalBars(
              active: isRunning,
              waveValue: waveValue,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({
    required this.angle,
    required this.radius,
    required this.color,
    required this.size,
  });

  final double angle;
  final double radius;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.active, required this.waveValue});

  final bool active;
  final double waveValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        final phase = (waveValue * 2 * math.pi) + (index * 0.72);
        final pulse = (math.sin(phase) + 1) / 2;
        final height = active
            ? (5 + (pulse * 15)).toDouble()
            : (4 + ((index % 2) * 2)).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 5,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? AppColors.primary400.withValues(alpha: 0.92)
                  : AppColors.textFaint.withValues(alpha: 0.65),
            ),
          ),
        );
      }),
    );
  }
}
