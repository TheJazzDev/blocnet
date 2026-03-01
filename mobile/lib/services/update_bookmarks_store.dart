import 'package:shared_preferences/shared_preferences.dart';

class UpdateBookmarksStore {
  UpdateBookmarksStore._();

  static const String _storageKey = 'blocnet_update_bookmark_ids';
  static Set<String>? _cachedIds;

  static Future<Set<String>> _loadIds() async {
    final cached = _cachedIds;
    if (cached != null) {
      return cached;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_storageKey) ?? const <String>[];
      final loaded = values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      _cachedIds = loaded;
      return loaded;
    } catch (_) {
      // Keep bookmarks functional in-memory if plugin storage is unavailable.
      final loaded = <String>{};
      _cachedIds = loaded;
      return loaded;
    }
  }

  static Future<bool> isBookmarked(String updateId) async {
    final normalized = updateId.trim();
    if (normalized.isEmpty) return false;

    final ids = await _loadIds();
    return ids.contains(normalized);
  }

  static Future<Set<String>> bookmarkedIds() async {
    final ids = await _loadIds();
    return {...ids};
  }

  static Future<bool> toggle(String updateId) async {
    final normalized = updateId.trim();
    if (normalized.isEmpty) return false;

    final ids = await _loadIds();
    final shouldBookmark = !ids.contains(normalized);

    if (shouldBookmark) {
      ids.add(normalized);
    } else {
      ids.remove(normalized);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, ids.toList(growable: false));
    } catch (_) {
      // Ignore persistence failures and keep current in-memory state.
    }
    _cachedIds = ids;
    return shouldBookmark;
  }

  static Future<bool> remove(String updateId) async {
    final normalized = updateId.trim();
    if (normalized.isEmpty) return false;

    final ids = await _loadIds();
    final wasRemoved = ids.remove(normalized);
    if (!wasRemoved) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, ids.toList(growable: false));
    } catch (_) {
      // Ignore persistence failures and keep current in-memory state.
    }
    _cachedIds = ids;
    return true;
  }
}
