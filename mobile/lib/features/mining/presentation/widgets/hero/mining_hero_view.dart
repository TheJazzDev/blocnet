import 'package:blocnet/features/mining/data/models/mining_models.dart';

/// What the Mine hero is showing. Resolved from data alone so every state can
/// be tested without pumping the animated card.
enum MiningHeroPhase {
  /// No snapshot yet and nothing has failed.
  loading,

  /// No snapshot and the last load failed: error + retry, never a made-up
  /// idle card (F-53).
  loadError,
  idle,
  running,

  /// Running, but the server clock says the cycle has ended and the server
  /// has not marked it claimable yet.
  finishing,
  claimable,
}

class MiningHeroView {
  const MiningHeroView({
    required this.phase,
    required this.isPaused,
    required this.cycleHours,
  });

  final MiningHeroPhase phase;

  /// `config.enabled` is false. New cycles cannot start; a finished cycle can
  /// still be claimed.
  final bool isPaused;
  final int cycleHours;

  bool get hasData =>
      phase != MiningHeroPhase.loading && phase != MiningHeroPhase.loadError;

  bool get canStart => phase == MiningHeroPhase.idle && !isPaused;

  /// `claimable` is the ONLY state that earns a Claim button. The clock
  /// reaching `endsAt` is not enough: a cycle past its claim window is
  /// forfeited server-side, so offering Claim there offers a button that
  /// cannot succeed (F-39).
  bool get canClaim => phase == MiningHeroPhase.claimable;

  bool get isLive =>
      phase == MiningHeroPhase.running || phase == MiningHeroPhase.finishing;

  static MiningHeroView resolve({
    required MiningSnapshot? snapshot,
    required bool isLoading,
    required String? loadError,
    required DateTime now,
  }) {
    if (snapshot == null) {
      final failed = !isLoading && (loadError?.isNotEmpty ?? false);
      return MiningHeroView(
        phase: failed ? MiningHeroPhase.loadError : MiningHeroPhase.loading,
        isPaused: false,
        cycleHours: 0,
      );
    }

    final session = snapshot.session;
    final MiningHeroPhase phase;
    if (session.isClaimable) {
      phase = MiningHeroPhase.claimable;
    } else if (session.isRunning) {
      phase = hasReachedEnd(session.endsAt, now)
          ? MiningHeroPhase.finishing
          : MiningHeroPhase.running;
    } else {
      phase = MiningHeroPhase.idle;
    }

    return MiningHeroView(
      phase: phase,
      isPaused: !snapshot.config.enabled,
      cycleHours: resolveCycleHours(snapshot),
    );
  }

  /// A real session omits `cycleHours`; the config is the source of truth.
  static int resolveCycleHours(MiningSnapshot snapshot) {
    return (snapshot.session.cycleHours ?? snapshot.config.cycleHours)
        .clamp(1, 168);
  }

  String get statusLabel {
    if (canClaim) return 'Claim Ready';
    if (isPaused) return 'Paused';
    if (isLive) return 'Live';
    return 'Idle';
  }

  String get statusSubtext {
    switch (phase) {
      case MiningHeroPhase.claimable:
        return 'Cycle complete. You can claim now.';
      case MiningHeroPhase.finishing:
        return 'Cycle finishing up. Pull to refresh in a moment.';
      case MiningHeroPhase.running:
        return 'Mining in progress';
      case MiningHeroPhase.idle:
        return isPaused
            ? 'Mining is paused'
            : 'Start to begin your ${cycleHours}h cycle.';
      case MiningHeroPhase.loading:
      case MiningHeroPhase.loadError:
        return '';
    }
  }

  static bool hasReachedEnd(DateTime? endsAt, DateTime now) {
    if (endsAt == null) return false;
    return !endsAt.toUtc().isAfter(now.toUtc());
  }

  /// `HH:MM:SS`, or `MM:SS` under an hour; `00:00` once ended.
  static String? formatCountdown(DateTime? endsAt, DateTime now) {
    if (endsAt == null) return null;
    final left = endsAt.toUtc().difference(now.toUtc());
    if (left.inSeconds <= 0) return '00:00';

    final totalSeconds = left.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    if (hours > 0) return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    return '${two(minutes)}:${two(seconds)}';
  }
}
