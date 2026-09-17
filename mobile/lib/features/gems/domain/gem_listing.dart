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

  /// The newest update's time, or the listing date when there is none.
  DateTime get lastActivity => newest?.createdAt ?? project.createdAt;
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
    final quietIds = QuietGems.detect(
      projects: projects,
      followedProjectIds: projects.map((p) => p.id).toSet(),
      posts: updates,
      now: now,
    ).map((q) => q.project.id).toSet();

    final out = <GemListing>[];
    for (final project in projects) {
      if (onlyIds != null && !onlyIds.contains(project.id)) continue;
      final own = byProject[project.id] ?? const <Update>[];
      out.add(GemListing(
        project: project,
        newest: _newest(own),
        updatesCount: project.updatesCount ?? own.length,
        nextDeadline: _nextDeadline(own, now),
        keeper: GemKeeper.forProject(project, known: hunters),
        isQuiet: quietIds.contains(project.id),
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
