import 'package:shared_preferences/shared_preferences.dart';

class UpdateLikesStore {
  UpdateLikesStore._();

  static const String _storageKey = 'blocnet_update_like_ids';
  static Set<String>? _cachedIds;

  static Future<Set<String>> _loadIds() async {
    final cached = _cachedIds;
    if (cached != null) {
      return cached;
    }

    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_storageKey) ?? const <String>[];
    final loaded = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    _cachedIds = loaded;
    return loaded;
  }

  static Future<bool> isLiked(String updateId) async {
    final normalized = updateId.trim();
    if (normalized.isEmpty) return false;

    final ids = await _loadIds();
    return ids.contains(normalized);
  }

  static Future<bool> toggle(String updateId) async {
    final normalized = updateId.trim();
    if (normalized.isEmpty) return false;

    final ids = await _loadIds();
    final shouldLike = !ids.contains(normalized);

    if (shouldLike) {
      ids.add(normalized);
    } else {
      ids.remove(normalized);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, ids.toList(growable: false));
    _cachedIds = ids;
    return shouldLike;
  }
}
