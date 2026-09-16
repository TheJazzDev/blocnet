import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';

/// One spoken summary of the cycle card (F-62).
///
/// Screen readers get this instead of the pill, ring and side column read
/// piece by piece. It names stated times, not the countdown, so it changes
/// when the state or the numbers change — not every minute.
String mineCycleSemanticsLabel(MineCycleView view) {
  final amount = view.centerNumber == null
      ? null
      : '${view.centerNumber} ${view.centerUnit}';
  final muted = _trimDot(view.whenMuted);

  switch (view.phase) {
    case MineCyclePhase.running:
      return ['Mining', _lower(view.whenBold), if (amount != null) amount]
          .join(', ');
    case MineCyclePhase.ready:
      return [
        'Ready to claim',
        if (amount != null) amount,
        if (muted.isNotEmpty) muted
      ].join(', ');
    case MineCyclePhase.closingSoon:
      return [
        'Closing soon',
        if (amount != null) amount,
        'expires ${muted.isEmpty ? 'soon' : muted}',
      ].join(', ');
    case MineCyclePhase.paused:
      return 'Mining is paused, $muted';
    case MineCyclePhase.idle:
      return 'Not mining. ${view.whenBold}, $muted';
    case MineCyclePhase.loading:
    case MineCyclePhase.loadError:
      return '';
  }
}

String _lower(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);

String _trimDot(String text) =>
    text.startsWith(' · ') ? text.substring(3) : text.trim();
