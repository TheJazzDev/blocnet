import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_core_visual.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_actions.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_notices.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_parts.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_stats.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_view.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_second_ticker.dart';
import 'package:flutter/material.dart';

class MiningHeroCard extends StatefulWidget {
  const MiningHeroCard({
    super.key,
    required this.snapshot,
    required this.onStart,
    required this.onClaim,
    required this.isStarting,
    required this.isClaiming,
    required this.isLoadingSnapshot,
    required this.serverNow,
    this.loadError,
    this.onRetry,
    this.onCycleEnd,
  });

  final MiningSnapshot? snapshot;
  final VoidCallback onStart;
  final VoidCallback onClaim;
  final bool isStarting;
  final bool isClaiming;
  final bool isLoadingSnapshot;

  /// Device clock corrected by the server's `asOf`. Every countdown reads it.
  final DateTime Function() serverNow;

  /// Why the first load failed. Only shown while there is no snapshot.
  final String? loadError;
  final VoidCallback? onRetry;

  /// Fired by the clock once a live cycle reaches its end. The store guards
  /// it so only one refetch happens per cycle.
  final VoidCallback? onCycleEnd;

  @override
  State<MiningHeroCard> createState() => _MiningHeroCardState();
}

class _MiningHeroCardState extends State<MiningHeroCard>
    with TickerProviderStateMixin, MiningSecondTicker<MiningHeroCard> {
  late final AnimationController _orbitController;
  late final AnimationController _counterOrbitController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late DateTime _now;
  bool _tabVisible = true;

  List<AnimationController> get _controllers => [
        _orbitController,
        _counterOrbitController,
        _pulseController,
        _waveController,
      ];

  @override
  void initState() {
    _now = widget.serverNow();
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
  }

  @override
  void didUpdateWidget(covariant MiningHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _now = widget.serverNow();
    _syncAnimationState();
    syncSecondTicker();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isLive => widget.snapshot?.session.isRunning == true;

  @override
  bool get shouldTick => _isLive;

  @override
  void onSecond() {
    setState(() => _now = widget.serverNow());
    final endsAt = widget.snapshot?.session.endsAt;
    if (_isLive && MiningHeroView.hasReachedEnd(endsAt, _now)) {
      widget.onCycleEnd?.call();
    }
  }

  @override
  void onTabVisibilityChanged(bool visible) {
    _tabVisible = visible;
    _syncAnimationState();
  }

  void _syncAnimationState() {
    if (_isLive && _tabVisible) {
      if (!_orbitController.isAnimating) _orbitController.repeat();
      if (!_counterOrbitController.isAnimating) {
        _counterOrbitController.repeat();
      }
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_waveController.isAnimating) _waveController.repeat();
      return;
    }
    for (final controller in _controllers) {
      controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final view = MiningHeroView.resolve(
      snapshot: snapshot,
      isLoading: widget.isLoadingSnapshot,
      loadError: widget.loadError,
      now: _now,
    );

    if (snapshot == null || !view.hasData) {
      if (view.phase == MiningHeroPhase.loadError) {
        return MiningHeroError(
          message: widget.loadError ?? '',
          onRetry: widget.onRetry ?? () {},
        );
      }
      return const MiningHeroLoading();
    }

    final action = resolveMiningAction(
      view: view,
      session: snapshot.session,
      now: _now,
      isStarting: widget.isStarting,
      isClaiming: widget.isClaiming,
      onStart: widget.onStart,
      onClaim: widget.onClaim,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const MiningHeroGlows(),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, AppSpace.xs, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroHeader(view: view),
              const SizedBox(height: AppSpace.md),
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge(_controllers),
                  builder: (context, _) => MiningCoreVisual(
                    isRunning: _isLive,
                    orbitValue: _orbitController.value,
                    counterOrbitValue: _counterOrbitController.value,
                    pulseValue: _pulseController.value,
                    waveValue: _waveController.value,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              MiningEarningPanel(
                snapshot: snapshot,
                cycleHours: view.cycleHours,
                canClaim: view.canClaim,
              ),
              const SizedBox(height: AppSpace.md),
              MiningStatsGrid(snapshot: snapshot),
              if (view.isPaused) ...[
                const SizedBox(height: AppSpace.md),
                MiningPausedNotice(canClaim: view.canClaim),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpace.lg),
                MiningActionButton(
                  label: action.label,
                  color: action.color,
                  textColor: action.textColor,
                  onPressed: action.onPressed,
                  isLoading: action.isLoading,
                  showLockIcon: action.showLockIcon,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.view});

  final MiningHeroView view;

  @override
  Widget build(BuildContext context) {
    final tagColor = view.canClaim
        ? AppColors.successColor
        : view.isPaused
            ? AppColors.warning500
            : view.isLive
                ? AppColors.primary500
                : AppColors.textFaint;

    return Row(
      children: [
        Icon(
          Icons.bolt_rounded,
          color: AppColors.primary400,
          size: AppIcon.md,
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(
            view.statusSubtext,
            style: AppTypography.custom(
              size: AppText.labelSize,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        MiningStatusTag(label: view.statusLabel, color: tagColor),
      ],
    );
  }
}
