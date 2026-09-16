import 'package:blocnet/features/mining/data/mine_boost.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';

/// Everything the cycle card prints, composed from data in the design's
/// copy patterns (see `docs/design-briefs/mine-build-spec.md`).
class MineCycleView {
  const MineCycleView({
    required this.phase,
    required this.pill,
    required this.rightLabel,
    required this.whenBold,
    required this.whenMuted,
    required this.ringFraction,
    required this.centerNumber,
    required this.centerUnit,
    required this.sideTop,
    required this.sideBottom,
    required this.buttonLabel,
    required this.note,
    required this.showNotify,
  });

  final MineCyclePhase phase;
  final String pill;
  final String rightLabel;
  final String whenBold;
  final String whenMuted;
  final double ringFraction;

  /// Null on idle and paused: the ring shows only the unit.
  final String? centerNumber;
  final String centerUnit;
  final String? sideTop;
  final String? sideBottom;

  /// Null when the state has no primary action (running, paused).
  final String? buttonLabel;
  final String? note;
  final bool showNotify;

  bool get isAmber => phase == MineCyclePhase.closingSoon;
  bool get canClaim =>
      phase == MineCyclePhase.ready || phase == MineCyclePhase.closingSoon;
  bool get canStart => phase == MineCyclePhase.idle;

  static const String notifyLabel = "Notify me when it's ready";
  static const String readyNote = 'Claiming starts your next cycle.';

  /// [activeFriends] is today's count (`/referrals/me`), used while no
  /// cycle carries its own boost snapshot.
  static MineCycleView resolve({
    required MineCyclePhase phase,
    required MiningSnapshot snapshot,
    required int activeFriends,
    required DateTime now,
  }) {
    final session = snapshot.session;
    final config = snapshot.config;
    final hours = MineCycleClock.cycleHours(snapshot);
    final fraction = MineCycleClock.ringFraction(phase, snapshot, now);
    final live = session.isRunning || session.isClaimable;
    final boost = live
        ? MineBoost(
            config: config,
            activeFriends: session.activeReferralsSnapshot,
            boostBps: session.boostBpsSnapshot,
          )
        : MineBoost.forFriends(config, activeFriends);
    final rate = '${boost.baseRate} BNP/hr';
    final claimPoints = MineFormat.points(session.pointsMinedSoFar);

    switch (phase) {
      case MineCyclePhase.running:
        final end = session.endsAt;
        final left = MineCycleClock.cycleTimeLeft(snapshot, now);
        final ended = left == null || left == Duration.zero;
        final mined =
            session.pointsMinedSoFar + session.currentHourEstimatedPoints;
        return MineCycleView(
          phase: phase,
          pill: 'MINING',
          rightLabel:
              'Hour ${MineCycleClock.currentHour(snapshot, now)} of $hours',
          whenBold: end == null
              ? 'Mining'
              : 'Ready ${MineFormat.relativeDay(end, now)} at '
                  '${MineFormat.clock(end)}',
          whenMuted:
              ended ? ' · now' : ' · ${MineFormat.shortDuration(left)} left',
          ringFraction: fraction,
          centerNumber: MineFormat.points(mined),
          centerUnit:
              'of ${MineFormat.points(session.effectivePointsPerCycle)} BNP',
          sideTop: rate,
          sideBottom: boost.sideLine,
          buttonLabel: null,
          note: null,
          showNotify: true,
        );
      case MineCyclePhase.ready:
        final deadline = MineCycleClock.claimDeadline(snapshot);
        return MineCycleView(
          phase: phase,
          pill: 'READY TO CLAIM',
          rightLabel: 'Cycle complete',
          whenBold: 'Ready to claim',
          whenMuted: deadline == null
              ? ''
              : ' · expires ${MineFormat.weekdayClock(deadline)}',
          ringFraction: fraction,
          centerNumber: claimPoints,
          centerUnit: 'BNP',
          sideTop: rate,
          sideBottom: boost.sideLine,
          buttonLabel: 'Claim $claimPoints BNP',
          note: readyNote,
          showNotify: false,
        );
      case MineCyclePhase.closingSoon:
        final deadline = MineCycleClock.claimDeadline(snapshot);
        final left = MineCycleClock.claimTimeLeft(snapshot, now);
        return MineCycleView(
          phase: phase,
          pill: 'CLOSING SOON',
          rightLabel: 'Claim window',
          whenBold: left == null
              ? 'Claim now'
              : 'Expires in ${MineFormat.shortDuration(left)}',
          whenMuted: deadline == null
              ? ''
              : ' · ${MineFormat.relativeDay(deadline, now)} at '
                  '${MineFormat.clock(deadline)}',
          ringFraction: fraction,
          centerNumber: claimPoints,
          centerUnit: 'BNP',
          sideTop: deadline == null
              ? null
              : 'Claim before ${MineFormat.clock(deadline)}',
          sideBottom: "or it's gone",
          buttonLabel: 'Claim $claimPoints BNP',
          note: null,
          showNotify: false,
        );
      case MineCyclePhase.paused:
        return MineCycleView(
          phase: phase,
          pill: 'PAUSED BY BLOCNET',
          rightLabel: 'All members',
          whenBold: 'Mining is paused',
          whenMuted: ' · your balance is safe',
          ringFraction: 0,
          centerNumber: null,
          centerUnit: 'Paused',
          sideTop: null,
          sideBottom: null,
          buttonLabel: null,
          note: null,
          showNotify: false,
        );
      case MineCyclePhase.idle:
      case MineCyclePhase.loading:
      case MineCyclePhase.loadError:
        return MineCycleView(
          phase: MineCyclePhase.idle,
          pill: 'NOT MINING',
          rightLabel: 'Cycle · ${hours}h',
          whenBold: 'Start mining',
          whenMuted: ' · ${MineFormat.points(boost.pointsPerCycle())} BNP '
              '${boost.perCycleUnit}',
          ringFraction: 0,
          centerNumber: null,
          centerUnit: '0 BNP',
          sideTop: rate,
          sideBottom: boost.sideLine,
          buttonLabel: 'Start mining',
          note: null,
          showNotify: MineCycleClock.hasMinedBefore(snapshot),
        );
    }
  }
}
