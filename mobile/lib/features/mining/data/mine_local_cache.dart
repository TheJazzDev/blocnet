import 'package:shared_preferences/shared_preferences.dart';

/// What the Mine tab remembers on the device.
///
/// Every call swallows storage failures: a missing plugin or a corrupt value
/// must never break the tab, it only loses the convenience.
class MineLocalCache {
  const MineLocalCache();

  static const String _balanceKey = 'mine.lastBalance';
  static const String _explainerKey = 'mine.explainerSeen';
  static const String _dismissedKey = 'mine.dismissedExpiredCycles';

  /// Keeps the list short: only the newest few dismissals matter.
  static const int _maxDismissed = 20;

  Future<int?> readBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_balanceKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeBalance(int balance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_balanceKey, balance);
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> clearBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_balanceKey);
    } catch (_) {
      // Best effort.
    }
  }

  Future<bool> hasSeenExplainer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_explainerKey) ?? false;
    } catch (_) {
      // Unknown: do not pop the explainer over a screen we cannot remember.
      return true;
    }
  }

  Future<void> markExplainerSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_explainerKey, true);
    } catch (_) {
      // Best effort.
    }
  }

  Future<Set<String>> dismissedExpiredCycles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_dismissedKey) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> dismissExpiredCycle(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_dismissedKey) ?? <String>[];
      if (list.contains(sessionId)) return;
      list.add(sessionId);
      final trimmed = list.length > _maxDismissed
          ? list.sublist(list.length - _maxDismissed)
          : list;
      await prefs.setStringList(_dismissedKey, trimmed);
    } catch (_) {
      // Best effort.
    }
  }
}
