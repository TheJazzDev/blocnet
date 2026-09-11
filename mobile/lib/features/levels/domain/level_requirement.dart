import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_number_format.dart';

/// The six metrics a level can gate on.
enum LevelMetric { bnp, comments, daysActive, quests, updates, projects }

/// One unlock criterion for a level, compared on raw values so formatted
/// strings such as `1.2K` never take part in the comparison.
class LevelRequirement {
  const LevelRequirement({
    required this.metric,
    required this.required,
    required this.current,
  });

  final LevelMetric metric;
  final BigInt required;
  final BigInt current;

  bool get isComplete => current >= required;

  BigInt get remaining {
    final diff = required - current;
    return diff.isNegative ? BigInt.zero : diff;
  }

  /// Progress in `0..1`. A zero requirement counts as complete.
  double get ratio {
    if (required <= BigInt.zero) return 1;
    if (current >= required) return 1;
    return current / required;
  }

  String get currentLabel => formatCompact(current);
  String get requiredLabel => formatCompact(required);
  String get remainingLabel => formatCompact(remaining);
}

/// Builds the non-zero requirements for [level], measured against
/// [metrics] (all zeros when progress has not loaded yet).
List<LevelRequirement> requirementsFor(
  UserLevelModel level, {
  UserMetrics? metrics,
}) {
  final rows = <LevelRequirement>[
    LevelRequirement(
      metric: LevelMetric.bnp,
      required: parseBigInt(level.requiredBnp),
      current: parseBigInt(metrics?.totalBnpEarned),
    ),
    LevelRequirement(
      metric: LevelMetric.comments,
      required: BigInt.from(level.requiredComments),
      current: BigInt.from(metrics?.totalComments ?? 0),
    ),
    LevelRequirement(
      metric: LevelMetric.daysActive,
      required: BigInt.from(level.requiredDaysActive),
      current: BigInt.from(metrics?.totalDaysActive ?? 0),
    ),
    LevelRequirement(
      metric: LevelMetric.quests,
      required: BigInt.from(level.requiredQuests),
      current: BigInt.from(metrics?.totalQuestsCompleted ?? 0),
    ),
    LevelRequirement(
      metric: LevelMetric.updates,
      required: BigInt.from(level.requiredUpdates),
      current: BigInt.from(metrics?.totalUpdates ?? 0),
    ),
    LevelRequirement(
      metric: LevelMetric.projects,
      required: BigInt.from(level.requiredProjects),
      current: BigInt.from(metrics?.totalProjects ?? 0),
    ),
  ];
  return rows.where((row) => row.required > BigInt.zero).toList();
}
