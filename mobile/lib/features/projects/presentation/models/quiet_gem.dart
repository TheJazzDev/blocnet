import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';

/// A gem the member follows whose hunter has stopped posting.
///
/// Blocnet's whole promise rests on hunters keeping gems current, and the
/// product's real failure mode is a hunter who posts a gem, collects followers
/// and abandons it. Nothing in the app told a member that was happening. This
/// is the detection for it, and it needs no schema change: the newest update's
/// timestamp is all the evidence there is.
class QuietGem {
  const QuietGem({
    required this.project,
    required this.lastUpdate,
    required this.silentFor,
  });

  final Project project;

  /// The newest update on this gem, or null when the hunter has never posted.
  final Update? lastUpdate;

  /// How long since that update. Measured from the project's creation when the
  /// hunter has never posted at all, which is the worse case.
  final Duration silentFor;

  int get daysSilent => silentFor.inDays;

  /// The hunter's handle, where the project carries one.
  String? get hunterHandle {
    final username = project.admin?.username.trim();
    if (username == null || username.isEmpty) return null;
    return username.startsWith('@') ? username : '@$username';
  }
}

/// Finds followed gems that have gone quiet.
class QuietGems {
  const QuietGems._();

  /// How long a gem may go untouched before the board says so.
  ///
  /// Two weeks: long enough that a hunter on holiday is not accused of
  /// abandonment, short enough that a member is not left waiting a month on a
  /// gem nobody is watching. A single constant because this is a product
  /// judgement that should be changed in one place.
  static const Duration silenceThreshold = Duration(days: 14);

  /// Returns one entry per followed gem that has not been touched inside
  /// [silenceThreshold], worst first.
  ///
  /// [posts] need not be complete — it is whatever the board currently holds.
  /// That makes this honest rather than authoritative, which matches what the
  /// card claims: not that the project is dead, only that nothing has come
  /// through.
  static List<QuietGem> detect({
    required Iterable<Project> projects,
    required Set<String> followedProjectIds,
    required Iterable<Update> posts,
    required DateTime now,
    Duration threshold = silenceThreshold,
  }) {
    final newestByProject = <String, Update>{};
    for (final post in posts) {
      final current = newestByProject[post.projectId];
      if (current == null || post.createdAt.isAfter(current.createdAt)) {
        newestByProject[post.projectId] = post;
      }
    }

    final quiet = <QuietGem>[];
    for (final project in projects) {
      if (!followedProjectIds.contains(project.id)) continue;
      final newest = newestByProject[project.id];
      // With no update at all, silence runs from when the gem was listed.
      final since = newest?.createdAt ?? project.createdAt;
      final silentFor = now.difference(since);
      if (silentFor < threshold) continue;
      quiet.add(
        QuietGem(project: project, lastUpdate: newest, silentFor: silentFor),
      );
    }

    quiet.sort((a, b) => b.silentFor.compareTo(a.silentFor));
    return quiet;
  }
}
