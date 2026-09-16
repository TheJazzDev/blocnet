import 'package:blocnet/services/projects/update_reactions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LegacySyncOutcome {
  /// No local ids were left; no request was made.
  nothingToSync,

  /// The ids were sent and the local keys cleared.
  imported,

  /// The request (or storage) failed; the keys stay for the next launch.
  failed,
}

/// Moves likes and saves the phone kept locally (before F-70) to the server.
///
/// Runs once: on success the old keys are removed, so every later launch
/// finds nothing and makes no request. On failure the keys stay and the next
/// launch tries again. Within one process it is attempted once, and
/// concurrent callers share that attempt.
class LegacyUpdateReactionsSync {
  LegacyUpdateReactionsSync({
    required UpdateReactionsRepository repository,
    Future<SharedPreferences> Function()? prefs,
  })  : _repository = repository,
        _prefs = prefs ?? SharedPreferences.getInstance;

  /// Where the removed `UpdateLikesStore` / `UpdateBookmarksStore` kept ids.
  static const String likesKey = 'blocnet_update_like_ids';
  static const String bookmarksKey = 'blocnet_update_bookmark_ids';

  final UpdateReactionsRepository _repository;
  final Future<SharedPreferences> Function() _prefs;
  Future<LegacySyncOutcome>? _run;

  Future<LegacySyncOutcome> runOnce() => _run ??= _migrate();

  Future<LegacySyncOutcome> _migrate() async {
    try {
      final prefs = await _prefs();
      final liked = _read(prefs, likesKey);
      final bookmarked = _read(prefs, bookmarksKey);
      if (liked.isEmpty && bookmarked.isEmpty) {
        await _clear(prefs);
        return LegacySyncOutcome.nothingToSync;
      }

      await _repository.importLocalReactions(
        likedUpdateIds: liked,
        bookmarkedUpdateIds: bookmarked,
      );
      await _clear(prefs);
      return LegacySyncOutcome.imported;
    } catch (_) {
      // Keep the keys; the next launch retries.
      return LegacySyncOutcome.failed;
    }
  }

  static List<String> _read(SharedPreferences prefs, String key) {
    final values = prefs.getStringList(key) ?? const <String>[];
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  static Future<void> _clear(SharedPreferences prefs) async {
    if (prefs.containsKey(likesKey)) await prefs.remove(likesKey);
    if (prefs.containsKey(bookmarksKey)) await prefs.remove(bookmarksKey);
  }
}
