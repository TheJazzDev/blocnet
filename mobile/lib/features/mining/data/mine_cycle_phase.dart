import 'package:blocnet/features/mining/data/models/mining_models.dart';

/// Which cycle card the Mine tab shows. Resolved from data and the server
/// clock alone, so every state is testable without pumping a widget.
enum MineCyclePhase {
  /// No snapshot yet and nothing has failed.
  loading,

  /// No snapshot and the last load failed: never a made-up idle card.
  loadError,
  idle,
  running,

  /// Claimable with more than [MineCycleClock.closingSoon] left.
  ready,

  /// Claimable with the claim window almost gone. Amber, never red.
  closingSoon,

  /// `config.enabled` is false and nothing is waiting to be claimed.
  paused,
}

class MineCycleClock {
  const MineCycleClock._();

  /// Matches the backend's switch from the "ready" to the "expiring" push
  /// (`MINING_EXPIRING_THRESHOLD_HOURS`).
  static const Duration closingSoon = Duration(hours: 6);

  static MineCyclePhase resolve({
    required MiningSnapshot? snapshot,
    required bool isLoading,
    required String? loadError,
    required DateTime now,
  }) {
    if (snapshot == null) {
      final failed = !isLoading && (loadError?.isNotEmpty ?? false);
      return failed ? MineCyclePhase.loadError : MineCyclePhase.loading;
    }

    final session = snapshot.session;
    // Claiming works while paused, so a finished cycle keeps its card.
    if (session.isClaimable) {
      final left = claimTimeLeft(snapshot, now);
      if (left != null && left <= closingSoon) {
        return MineCyclePhase.closingSoon;
      }
      return MineCyclePhase.ready;
    }
    if (!snapshot.config.enabled) return MineCyclePhase.paused;
    if (session.isRunning) return MineCyclePhase.running;
    return MineCyclePhase.idle;
  }

  /// A real session omits `cycleHours`; the config is the source of truth.
  static int cycleHours(MiningSnapshot snapshot) =>
      (snapshot.session.cycleHours ?? snapshot.config.cycleHours).clamp(1, 168);

  /// `endsAt` plus the claim window.
  static DateTime? claimDeadline(MiningSnapshot snapshot) {
    final endsAt = snapshot.session.endsAt;
    if (endsAt == null) return null;
    return endsAt.add(Duration(hours: snapshot.config.claimWindowHours));
  }

  static Duration? claimTimeLeft(MiningSnapshot snapshot, DateTime now) {
    final deadline = claimDeadline(snapshot);
    if (deadline == null) return null;
    final left = deadline.toUtc().difference(now.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  static Duration? cycleTimeLeft(MiningSnapshot snapshot, DateTime now) {
    final endsAt = snapshot.session.endsAt;
    if (endsAt == null) return null;
    final left = endsAt.toUtc().difference(now.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  static bool hasReachedEnd(DateTime? endsAt, DateTime now) {
    if (endsAt == null) return false;
    return !endsAt.toUtc().isAfter(now.toUtc());
  }

  /// Elapsed share of the running cycle, by time (the design's 35.42 % at
  /// 8.5 of 24 hours). Falls back to the server's `progressPct`.
  static double elapsedFraction(MiningSnapshot snapshot, DateTime now) {
    final session = snapshot.session;
    final start = session.startsAt;
    final end = session.endsAt;
    if (start == null || end == null || !end.isAfter(start)) {
      final pct = session.progressPct;
      return (pct > 1 ? pct / 100 : pct).clamp(0.0, 1.0);
    }
    final total = end.difference(start).inSeconds;
    final done = now.toUtc().difference(start.toUtc()).inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  /// Hours into the cycle, rounded up and at least 1.
  static int currentHour(MiningSnapshot snapshot, DateTime now) {
    final hours = cycleHours(snapshot);
    final start = snapshot.session.startsAt;
    if (start == null) {
      return (snapshot.session.completedHours).clamp(1, hours);
    }
    final minutes = now.toUtc().difference(start.toUtc()).inMinutes;
    return (minutes / 60).ceil().clamp(1, hours);
  }

  /// Ring fill for [phase]: elapsed time while running, the claim window
  /// left when closing soon, full when ready, empty otherwise.
  static double ringFraction(
    MineCyclePhase phase,
    MiningSnapshot snapshot,
    DateTime now,
  ) {
    switch (phase) {
      case MineCyclePhase.running:
        return elapsedFraction(snapshot, now);
      case MineCyclePhase.ready:
        return 1;
      case MineCyclePhase.closingSoon:
        final left = claimTimeLeft(snapshot, now);
        final window = snapshot.config.claimWindowHours * 3600;
        if (left == null || window <= 0) return 0;
        return (left.inSeconds / window).clamp(0.0, 1.0);
      case MineCyclePhase.idle:
      case MineCyclePhase.paused:
      case MineCyclePhase.loading:
      case MineCyclePhase.loadError:
        return 0;
    }
  }

  /// Whether this account has ever mined: gates the idle notify row.
  static bool hasMinedBefore(MiningSnapshot snapshot) =>
      snapshot.balance.lifetimeEarnedPoints > 0 ||
      snapshot.balance.claimedTotalPoints > 0 ||
      snapshot.lastExpiredCycle != null ||
      snapshot.hourlyHistory.isNotEmpty;
}
