import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/api/api_client.dart';

/// Server state of one member's like on one update.
class UpdateLikeResult {
  const UpdateLikeResult({required this.liked, required this.likesCount});

  final bool liked;
  final int likesCount;
}

/// Server state of one member's save on one update.
class UpdateBookmarkResult {
  const UpdateBookmarkResult({
    required this.bookmarked,
    required this.bookmarksCount,
  });

  final bool bookmarked;
  final int bookmarksCount;
}

/// HTTP calls for likes and saves on updates. Every write is idempotent on
/// the server, so a retry can never double-count.
class UpdateReactionsRepository {
  UpdateReactionsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// The server caps each list of the one-time import at this many ids.
  static const int importLimit = 500;

  Future<UpdateLikeResult> setLiked(String updateId, bool liked) async {
    final path = '/updates/${Uri.encodeComponent(updateId)}/like';
    final response =
        liked ? await _apiClient.put(path) : await _apiClient.delete(path);
    final map = _asMap(response);
    return UpdateLikeResult(
      liked: map['liked'] is bool ? map['liked'] as bool : liked,
      likesCount: _asInt(map['likesCount']),
    );
  }

  Future<UpdateBookmarkResult> setBookmarked(
    String updateId,
    bool bookmarked,
  ) async {
    final path = '/updates/${Uri.encodeComponent(updateId)}/bookmark';
    final response =
        bookmarked ? await _apiClient.put(path) : await _apiClient.delete(path);
    final map = _asMap(response);
    return UpdateBookmarkResult(
      bookmarked:
          map['bookmarked'] is bool ? map['bookmarked'] as bool : bookmarked,
      bookmarksCount: _asInt(map['bookmarksCount']),
    );
  }

  /// The member's saved updates, newest saved first.
  Future<List<Update>> fetchSavedUpdates({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/me/bookmarks/updates',
      query: {'limit': '$limit', 'offset': '$offset'},
    );
    if (response is! List) return const <Update>[];
    return response
        .whereType<Map<String, dynamic>>()
        .map(Update.fromApi)
        .toList();
  }

  /// Sends the ids the phone used to keep locally. Lists longer than
  /// [importLimit] are trimmed; the server would reject them otherwise.
  Future<void> importLocalReactions({
    required List<String> likedUpdateIds,
    required List<String> bookmarkedUpdateIds,
  }) async {
    await _apiClient.post(
      '/me/update-reactions/import',
      body: {
        'likedUpdateIds': likedUpdateIds.take(importLimit).toList(),
        'bookmarkedUpdateIds': bookmarkedUpdateIds.take(importLimit).toList(),
      },
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static int _asInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
