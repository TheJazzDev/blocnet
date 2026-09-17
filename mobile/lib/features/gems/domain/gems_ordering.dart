import 'package:blocnet/features/gems/domain/gem_listing.dart';

/// Discover's sort options. Each one sorts by a number the server sends or
/// a time the phone holds; none of them is a score.
enum GemSort {
  mostActive('Most active'),
  mostFollowed('Most followed'),
  newest('Newest');

  const GemSort(this.label);

  final String label;
}

class GemsOrdering {
  const GemsOrdering._();

  /// How far back "Moving across Blocnet" looks.
  static const Duration movingWindow = Duration(days: 7);

  /// How many gems "Moving across Blocnet" shows.
  static const int movingLimit = 4;

  /// A deadline this close puts a followed gem at the top of the board.
  static const Duration boardDeadlineWindow = Duration(days: 7);

  /// An update this recent counts as news on the board.
  static const Duration boardFreshWindow = Duration(days: 7);

  /// Discover's list: filtered to [tag] (a primary tag name, case-insensitive)
  /// and sorted by [sort].
  static List<GemListing> discover(
    List<GemListing> gems, {
    required GemSort sort,
    String? tag,
  }) {
    final wanted = tag?.trim().toLowerCase();
    final out = gems
        .where((g) =>
            wanted == null ||
            wanted.isEmpty ||
            g.project.primaryTag.name.trim().toLowerCase() == wanted)
        .toList();
    out.sort((a, b) {
      final primary = switch (sort) {
        GemSort.mostActive => _byNewestUpdate(a, b),
        GemSort.mostFollowed =>
          b.project.followersCount.compareTo(a.project.followersCount),
        GemSort.newest => b.project.createdAt.compareTo(a.project.createdAt),
      };
      if (primary != 0) return primary;
      return b.project.createdAt.compareTo(a.project.createdAt);
    });
    return out;
  }

  /// Gems that had an update inside [movingWindow], newest first.
  static List<GemListing> moving(List<GemListing> gems, DateTime now) {
    final since = now.subtract(movingWindow);
    final out = gems
        .where((g) => g.newest != null && g.newest!.createdAt.isAfter(since))
        .toList()
      ..sort(_byNewestUpdate);
    return out.take(movingLimit).toList();
  }

  /// The member's board, most in need of them first: a deadline in the next
  /// week (soonest first), then gems with an update in the last week, then
  /// the rest. Newest update first inside the last two groups.
  static List<GemListing> board(List<GemListing> gems, DateTime now) {
    int group(GemListing g) {
      final deadline = g.nextDeadline?.deadlineAt;
      if (deadline != null &&
          deadline.isBefore(now.add(boardDeadlineWindow))) {
        return 0;
      }
      final newest = g.newest?.createdAt;
      if (newest != null && newest.isAfter(now.subtract(boardFreshWindow))) {
        return 1;
      }
      return 2;
    }

    final out = [...gems];
    out.sort((a, b) {
      final ga = group(a);
      final gb = group(b);
      if (ga != gb) return ga.compareTo(gb);
      if (ga == 0) {
        return a.nextDeadline!.deadlineAt!
            .compareTo(b.nextDeadline!.deadlineAt!);
      }
      return _byNewestUpdate(a, b);
    });
    return out;
  }

  /// The primary tags present in [gems], sorted, for the filter row.
  static List<String> tags(List<GemListing> gems) {
    final seen = <String, String>{};
    for (final g in gems) {
      final name = g.project.primaryTag.name.trim();
      if (name.isEmpty) continue;
      seen.putIfAbsent(name.toLowerCase(), () => name);
    }
    return seen.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Newest update first; gems with none go last.
  static int _byNewestUpdate(GemListing a, GemListing b) {
    final at = a.newest?.createdAt;
    final bt = b.newest?.createdAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  }
}
