import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';

/// Plain-English copy for the forfeited-cycle cases.
///
/// Kept out of the widgets and the store so the wording lives in one place and
/// can be unit tested. The rule the copy follows: say what was lost, say how
/// much, and say what happens next — no error codes, no blame.
class MiningExpiryCopy {
  const MiningExpiryCopy._();

  /// Shown after a Claim tap that forfeited instead of paying out.
  static String claimExpired(MiningClaimResult result,
      {int? claimWindowHours}) {
    final count =
        result.expiredCycles.isEmpty ? 1 : result.expiredCycles.length;
    final lost = _points(result.forfeitedPoints);

    final what = count == 1
        ? 'Your mining cycle ran out of time before you claimed it'
        : '$count of your mining cycles ran out of time before you claimed them';

    final amount = result.forfeitedPoints > 0
        ? ', so $lost BNP was forfeited.'
        : ', so nothing was paid out.';

    return '$what$amount ${_whatNext(result, claimWindowHours)}';
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
}
