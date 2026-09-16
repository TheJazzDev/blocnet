import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_hero_view.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:flutter/material.dart';

/// One spoken summary of the hero's status, clock and earnings (F-62).
///
/// Screen readers get this instead of the header, orbit and panel read
/// piece by piece ("0%", "IDLE", ...). It names an absolute ready time, not
/// the ticking countdown, so the label only changes when the state or the
/// numbers do — not every second.
String miningHeroSemanticsLabel(
  BuildContext context, {
  required MiningHeroView view,
  required MiningSessionModel session,
  required DateTime now,
}) {
  final earned = formatGroupedNumber(
    session.pointsMinedSoFar + session.currentHourEstimatedPoints,
    maxDecimals: 2,
  );
  final rate = formatGroupedNumber(session.hourlyRateNow, maxDecimals: 2);

  switch (view.phase) {
    case MiningHeroPhase.claimable:
      return 'Mining cycle complete, $earned BNP ready to claim';
    case MiningHeroPhase.finishing:
      return 'Mining cycle finishing, $earned BNP so far';
    case MiningHeroPhase.running:
      final readyAt = _readyAt(context, session.endsAt, now);
      final paused = view.isPaused ? ', mining is paused' : '';
      return [
        'Mining$paused',
        if (readyAt != null) 'ready at $readyAt',
        '$earned BNP so far',
      ].join(', ');
    case MiningHeroPhase.idle:
      return view.isPaused
          ? 'Mining is paused'
          : 'Not mining. Start to begin your ${view.cycleHours} hour cycle, '
              'earning $rate BNP per hour';
    case MiningHeroPhase.loading:
    case MiningHeroPhase.loadError:
      return '';
  }
}

/// "12:05 today", "12:05 tomorrow", or "12:05, Sep 20, 2026" further out.
String? _readyAt(BuildContext context, DateTime? endsAt, DateTime now) {
  if (endsAt == null) return null;
  final end = endsAt.toLocal();
  final today = DateUtils.dateOnly(now.toLocal());
  final localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(end),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  // Rounded so a DST change (a 23h or 25h day) still counts as one day.
  final dayGap =
      (DateUtils.dateOnly(end).difference(today).inHours / 24).round();
  if (dayGap <= 0) return '$time today';
  if (dayGap == 1) return '$time tomorrow';
  return '$time, ${localizations.formatMediumDate(end)}';
}
