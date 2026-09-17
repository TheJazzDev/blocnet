import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_body.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_second_ticker.dart';
import 'package:flutter/material.dart';

/// The Mine cycle card: idle, running, ready, closing soon or paused.
///
/// Owns the clock (so times and the ring follow the server clock) and the
/// two breathing animations: the running ring's glow (2.4 s) and the ready
/// card's edge (3.2 s). Both stop under reduced motion and while the tab is
/// hidden.
class MineCycleCard extends StatefulWidget {
  const MineCycleCard({
    super.key,
    required this.snapshot,
    required this.activeFriends,
    required this.serverNow,
    required this.onStart,
    required this.onClaim,
    this.isStarting = false,
    this.isClaiming = false,
    this.onCycleEnd,
  });

  final MiningSnapshot snapshot;

  /// Today's active friends, for the idle card's boost line.
  final int activeFriends;

  /// Device clock corrected by the server's `asOf`.
  final DateTime Function() serverNow;
  final VoidCallback onStart;
  final VoidCallback onClaim;
  final bool isStarting;
  final bool isClaiming;

  /// Fired once a running cycle reaches its end; the store guards repeats.
  final VoidCallback? onCycleEnd;

  @override
  State<MineCycleCard> createState() => _MineCycleCardState();
}

class _MineCycleCardState extends State<MineCycleCard>
    with TickerProviderStateMixin, MiningSecondTicker<MineCycleCard> {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _edge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late DateTime _now;
  bool _tabVisible = true;

  MineCyclePhase get _phase => MineCycleClock.resolve(
        snapshot: widget.snapshot,
        isLoading: false,
        loadError: null,
        now: _now,
      );

  @override
  void initState() {
    _now = widget.serverNow();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant MineCycleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _now = widget.serverNow();
    _syncAnimations();
    syncSecondTicker();
  }

  @override
  void dispose() {
    _glow.dispose();
    _edge.dispose();
    super.dispose();
  }

  bool get _isLive =>
      widget.snapshot.session.isRunning || widget.snapshot.session.isClaimable;

  @override
  bool get shouldTick => _isLive;

  @override
  void onSecond() {
    setState(() => _now = widget.serverNow());
    _syncAnimations();
    final session = widget.snapshot.session;
    if (session.isRunning &&
        MineCycleClock.hasReachedEnd(session.endsAt, _now)) {
      widget.onCycleEnd?.call();
    }
  }

  @override
  void onTabVisibilityChanged(bool visible) {
    _tabVisible = visible;
    _syncAnimations();
  }

  void _syncAnimations() {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final phase = _phase;
    _run(_glow, phase == MineCyclePhase.running && _tabVisible && !reduced);
    _run(_edge, phase == MineCyclePhase.ready && _tabVisible && !reduced);
  }

  void _run(AnimationController controller, bool on) {
    if (on) {
      if (!controller.isAnimating) controller.repeat(reverse: true);
    } else if (controller.isAnimating) {
      controller
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;
    final view = MineCycleView.resolve(
      phase: phase,
      snapshot: widget.snapshot,
      activeFriends: widget.activeFriends,
      now: _now,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_glow, _edge]),
      builder: (context, child) => DecoratedBox(
        key: const ValueKey('mine-cycle-card'),
        decoration: _decoration(phase, _edge.value),
        child: child,
      ),
      child: Padding(
        padding: AppSpace.card,
        child: MineCycleBody(
          view: view,
          glow: _glow,
          isBusy: widget.isStarting || widget.isClaiming,
          onStart: widget.onStart,
          onClaim: widget.onClaim,
        ),
      ),
    );
  }

  /// Flat grounds only. Live states take the old "EARNING PER HOUR" panel's
  /// accent wash; the ready edge breathes between 20 % and 55 %.
  BoxDecoration _decoration(MineCyclePhase phase, double breath) {
    switch (phase) {
      case MineCyclePhase.running:
        return _card(MinePalette.accentWash, MinePalette.accentEdge);
      case MineCyclePhase.ready:
        final tone = MinePalette.success;
        return _card(
          tone.withValues(alpha: 0.08),
          tone.withValues(alpha: 0.2 + 0.35 * breath),
        );
      case MineCyclePhase.closingSoon:
        final tone = MinePalette.amber;
        return _card(
          tone.withValues(alpha: 0.08),
          tone.withValues(alpha: 0.3),
        );
      case MineCyclePhase.paused:
        return _card(MinePalette.card, MinePalette.strongEdge);
      case MineCyclePhase.idle:
      case MineCyclePhase.loading:
      case MineCyclePhase.loadError:
        return _card(MinePalette.card, MinePalette.edge);
    }
  }

  static BoxDecoration _card(Color ground, Color edge) {
    return BoxDecoration(
      color: ground,
      borderRadius: AppRadius.xl,
      border: Border.all(color: edge),
    );
  }
}
