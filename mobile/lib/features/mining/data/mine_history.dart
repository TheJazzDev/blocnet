import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';

/// How a cycle in the hourly history ended.
enum MineCycleOutcome { claimed, waiting, expired }

/// One cycle of the hourly history: its checkpoints, newest hour first.
class MineHistoryGroup {
  const MineHistoryGroup({
    required this.sessionId,
    required this.hours,
    required this.isCurrent,
  });

  final String sessionId;
  final List<MiningHourlyCheckpointModel> hours;

  /// The cycle the member is mining right now.
  final bool isCurrent;

  MineCycleOutcome get outcome {
    if (hours.any((hour) => hour.isExpired)) return MineCycleOutcome.expired;
    if (hours.isNotEmpty && hours.every((hour) => hour.isClaimed)) {
      return MineCycleOutcome.claimed;
    }
    return MineCycleOutcome.waiting;
  }

  /// BNP this cycle paid: claimed hours only, so an expired cycle reads 0.
  double get claimedPoints => hours
      .where((hour) => hour.isClaimed)
      .fold<double>(0, (sum, hour) => sum + hour.points);

  double get totalPoints =>
      hours.fold<double>(0, (sum, hour) => sum + hour.points);

  DateTime? get startedAt {
    DateTime? earliest;
    for (final hour in hours) {
      final start = hour.hourStartAt;
      if (start == null) continue;
      if (earliest == null || start.isBefore(earliest)) earliest = start;
    }
    return earliest;
  }

  /// `16 Sep · now` / `15 Sep · 132 BNP` / `14 Sep · 0 BNP`
  String get title {
    final start = startedAt;
    final day = start == null ? 'Cycle' : MineFormat.dayMonth(start);
    if (isCurrent) return '$day · now';
    final points =
        outcome == MineCycleOutcome.waiting ? totalPoints : claimedPoints;
    return '$day · ${MineFormat.points(points)} BNP';
  }

  String get pill => switch (outcome) {
        MineCycleOutcome.claimed => 'CLAIMED',
        MineCycleOutcome.waiting => 'NOT CLAIMED',
        MineCycleOutcome.expired => 'EXPIRED',
      };
}

class MineHistory {
  const MineHistory._();

  /// Groups checkpoints by `sessionId`, newest cycle first and newest hour
  /// first inside each.
  static List<MineHistoryGroup> group(
    List<MiningHourlyCheckpointModel> checkpoints, {
    String? currentSessionId,
  }) {
    final bySession = <String, List<MiningHourlyCheckpointModel>>{};
    for (final checkpoint in checkpoints) {
      bySession.putIfAbsent(checkpoint.sessionId, () => []).add(checkpoint);
    }

    final groups = bySession.entries.map((entry) {
      final hours = [...entry.value]..sort(_newestHourFirst);
      return MineHistoryGroup(
        sessionId: entry.key,
        hours: hours,
        isCurrent: entry.key == currentSessionId,
      );
    }).toList();

    groups.sort((a, b) {
      final aStart = a.startedAt;
      final bStart = b.startedAt;
      if (aStart == null || bStart == null) return 0;
      return bStart.compareTo(aStart);
    });
    return groups;
  }

  static int _newestHourFirst(
    MiningHourlyCheckpointModel a,
    MiningHourlyCheckpointModel b,
  ) {
    final aStart = a.hourStartAt;
    final bStart = b.hourStartAt;
    if (aStart == null || bStart == null) {
      return b.hourIndex.compareTo(a.hourIndex);
    }
    return bStart.compareTo(aStart);
  }

  /// The Mine tab's one-line summary, or null when there is nothing to show.
  ///
  /// `1 claimed · 1 expired` · `2 claimed · 264 BNP` · `49 BNP so far`.
  static String? summary(List<MineHistoryGroup> groups) {
    if (groups.isEmpty) return null;
    final claimed = groups
        .where((group) => group.outcome == MineCycleOutcome.claimed)
        .toList();
    final expired = groups
        .where((group) => group.outcome == MineCycleOutcome.expired)
        .length;

    if (expired > 0) return '${claimed.length} claimed · $expired expired';
    if (claimed.isNotEmpty) {
      final paid = claimed.fold<double>(
        0,
        (sum, group) => sum + group.claimedPoints,
      );
      return '${claimed.length} claimed · ${MineFormat.points(paid)} BNP';
    }
    final pending = groups.fold<double>(
      0,
      (sum, group) => sum + group.totalPoints,
    );
    return '${MineFormat.points(pending)} BNP so far';
  }

  static String hourState(MiningHourlyCheckpointModel hour) {
    if (hour.isClaimed) return 'Claimed';
    if (hour.isExpired) return 'Expired';
    return 'Waiting';
  }
}
