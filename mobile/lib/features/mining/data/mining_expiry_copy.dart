import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';

/// Plain-English copy for the forfeited-cycle cases.
///
/// Kept out of the widgets and the store so the wording lives in one place and
/// can be unit tested. The rule the copy follows: say what was lost, say how
/// much, and say what happens next — no error codes, no blame.
class MiningExpiryCopy {
  const MiningExpiryCopy._();

  static const String noticeTitle = 'You missed a claim window';

  /// Shown after a Claim tap that forfeited instead of paying out.
  static String claimExpired(MiningClaimResult result, {int? claimWindowHours}) {
    final count = result.expiredCycles.isEmpty ? 1 : result.expiredCycles.length;
    final lost = _points(result.forfeitedPoints);

    final what = count == 1
        ? 'Your mining cycle ran out of time before you claimed it'
        : '$count of your mining cycles ran out of time before you claimed them';

    final amount = result.forfeitedPoints > 0
        ? ', so $lost BNP was forfeited.'
        : ', so nothing was paid out.';

    return '$what$amount ${_whatNext(result, claimWindowHours)}';
  }

  /// Shown on the mining screen while [cycle] is the account's most recent
  /// forfeited cycle.
  static String lastExpiredCycle(
    MiningExpiredCycle cycle, {
    required int claimWindowHours,
  }) {
    final ended = cycle.endsAt;
    final when = ended == null ? 'A finished cycle' : 'The cycle that ended ${_date(ended)}';
    final lost = _points(cycle.forfeitedPoints);

    final amount = cycle.forfeitedPoints > 0
        ? '$lost BNP was forfeited'
        : 'its points were forfeited';

    return '$when was never claimed, so $amount. '
        'Points only reach your balance when you claim, so claim within '
        '${_hours(claimWindowHours)} of a cycle finishing.';
  }

  /// Shown after Start when the backend forfeited older cycles on the way.
  static String startForfeited(MiningStartResult result) {
    final count = result.expiredCycles.length;
    final lost = _points(result.forfeitedPoints);
    final cycles = count == 1 ? 'An older cycle' : '$count older cycles';
    final verb = count == 1 ? 'was' : 'were';

    if (result.forfeitedPoints > 0) {
      return '$cycles $verb past the claim window and $verb forfeited '
          '($lost BNP). Your new cycle is running.';
    }
    return '$cycles $verb past the claim window and $verb closed out. '
        'Your new cycle is running.';
  }

  /// Row label in the hourly history for the third checkpoint state.
  static String checkpointStatusLabel(MiningHourlyCheckpointModel item) {
    if (item.isClaimed) return 'Claimed';
    if (item.isExpired) return 'Expired';
    return 'Unclaimed';
  }

  static String _whatNext(MiningClaimResult result, int? claimWindowHours) {
    if (!result.startedNextCycle) {
      return 'Start a new cycle whenever you are ready.';
    }
    if (claimWindowHours == null) {
      return 'A new cycle has already started for you — claim that one as soon as it finishes.';
    }
    return 'A new cycle has already started for you — claim it within '
        '${_hours(claimWindowHours)} of finishing.';
  }

  static String _points(int points) {
    return formatGroupedNumber(points, maxDecimals: 0);
  }

  static String _hours(int hours) {
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  static String _date(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    if (local.month < 1 || local.month > 12) return 'recently';
    return '${months[local.month - 1]} ${local.day}';
  }
}
