import 'package:shared_preferences/shared_preferences.dart';

class ProjectFollowsStore {
  ProjectFollowsStore._();

  static const String _storageKey = 'blocnet_followed_project_ids';
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
      final loaded = <String>{};
      _cachedIds = loaded;
      return loaded;
    }
  }

  static Future<Set<String>> followedIds() async {
    final ids = await _loadIds();
    return Set<String>.from(ids);
  }

  static Future<void> replaceAll(Iterable<String> projectIds) async {
    final normalized = projectIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    _cachedIds = normalized;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _storageKey, normalized.toList(growable: false));
    } catch (_) {
      // Keep in-memory fallback if persistence is unavailable.
    }
  }
}
