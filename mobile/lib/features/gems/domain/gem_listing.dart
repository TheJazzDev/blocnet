import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/quiet_gem.dart';

/// One gem with the facts a card shows: its newest update, how many updates
/// it has, its next stated deadline, and who keeps it.
class GemListing {
  const GemListing({
    required this.project,
    required this.updatesCount,
    required this.isQuiet,
    this.newest,
    this.nextDeadline,
    this.keeper,
  });

  final Project project;
  final Update? newest;
  final int updatesCount;

  /// The loaded update whose stated deadline comes next, if any is ahead.
  final Update? nextDeadline;
  final GemKeeper? keeper;

  /// Untouched for [QuietGems.silenceThreshold] — the same rule as Home.
  final bool isQuiet;

  String get id => project.id;

  /// When the gem last had an update: the server's time, or the newest loaded
  /// update when the server did not say. Null when it never had one.
  DateTime? get lastUpdateAt => _later(project.lastUpdateAt, newest?.createdAt);

  /// [newest] is the gem's latest update, not just the latest one loaded.
  bool get newestIsLatest {
    final loaded = newest?.createdAt;
    return loaded != null && !lastUpdateAt!.isAfter(loaded);
  }

  /// The last update's time, or the listing date when there is none.
  DateTime get lastActivity => lastUpdateAt ?? project.createdAt;
}

/// Builds [GemListing]s from what the stores hold.
class GemListings {
  const GemListings._();

  static List<GemListing> build({
    required Iterable<Project> projects,
    required Iterable<Update> updates,
    required DateTime now,
    Map<String, HunterReliability> hunters = const {},
    Set<String>? onlyIds,
  }) {
    final byProject = <String, List<Update>>{};
    for (final update in updates) {
      byProject.putIfAbsent(update.projectId, () => []).add(update);
    }
    final out = <GemListing>[];
    for (final project in projects) {
      if (onlyIds != null && !onlyIds.contains(project.id)) continue;
      final own = byProject[project.id] ?? const <Update>[];
      final newest = _newest(own);
      final lastActivity =
          _later(project.lastUpdateAt, newest?.createdAt) ?? project.createdAt;
      out.add(GemListing(
        project: project,
        newest: newest,
        updatesCount: project.updatesCount ?? own.length,
        nextDeadline: _nextDeadline(own, now),
        keeper: GemKeeper.forProject(project, known: hunters),
        // Home's rule, measured from the server's last update when known.
        isQuiet: now.difference(lastActivity) >= QuietGems.silenceThreshold,
      ));
    }
    return out;
  }

  static Update? _newest(List<Update> updates) {
    Update? newest;
    for (final u in updates) {
      if (newest == null || u.createdAt.isAfter(newest.createdAt)) newest = u;
    }
    return newest;
  }

  static Update? _nextDeadline(List<Update> updates, DateTime now) {
    Update? next;
    for (final u in updates) {
      final at = u.deadlineAt;
      if (at == null || at.isBefore(now)) continue;
      if (next == null || at.isBefore(next.deadlineAt!)) next = u;
    }
    return next;
  }
}

DateTime? _later(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
