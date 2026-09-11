import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/foundation.dart';

class LevelsStore with ChangeNotifier {
  final ApiClient _api;

  LevelsStore({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  List<UserLevelModel> _allLevels = [];
  UserLevelProgressModel? _myProgress;
  bool _isLoadingLevels = false;
  bool _isLoadingProgress = false;
  bool _isRecalculating = false;
  bool _levelChanged = false;
  String? _levelsError;
  String? _progressError;
  Future<void>? _inFlightProgress;
  final Map<String, UserLevelProgressModel> _userProgressByUserId = {};
  final Map<String, Future<UserLevelProgressModel?>> _inFlightUserLevels = {};

  List<UserLevelModel> get allLevels => _allLevels;
  UserLevelProgressModel? get myProgress => _myProgress;
  bool get isLoadingLevels => _isLoadingLevels;
  bool get isLoadingProgress => _isLoadingProgress;
  bool get isRecalculating => _isRecalculating;

  /// Whether the most recent [recalculateMyLevel] call moved the user to a
  /// different level. Reset at the start of every recalculation.
  bool get levelChanged => _levelChanged;
  String? get levelsError => _levelsError;
  String? get progressError => _progressError;

  UserLevelModel? cachedLevelForUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return null;
    return _userProgressByUserId[normalized]?.currentLevel;
  }

  /// Fetch all levels from the API
  Future<void> fetchAllLevels() async {
    if (_isLoadingLevels) return;

    _isLoadingLevels = true;
    _levelsError = null;
    notifyListeners();

    try {
      final response = await _api.get('/levels');
      if (response is List) {
        _allLevels = response
            .map((item) => UserLevelModel.fromApi(item as Map<String, dynamic>))
            .toList();
        _allLevels.sort((a, b) => a.level.compareTo(b.level));
      }
      _levelsError = null;
    } on ApiException catch (e) {
      _levelsError = e.message;
    } catch (e) {
      _levelsError = 'Failed to load levels';
    } finally {
      _isLoadingLevels = false;
      notifyListeners();
    }
  }

  /// Fetch the current user's level progress.
  ///
  /// Concurrent callers share the in-flight request instead of firing a
  /// second one.
  Future<void> fetchMyProgress() {
    final inFlight = _inFlightProgress;
    if (inFlight != null) return inFlight;

    final request = _fetchMyProgress();
    _inFlightProgress = request;
    return request.whenComplete(() {
      if (identical(_inFlightProgress, request)) _inFlightProgress = null;
    });
  }

  Future<void> _fetchMyProgress() async {
    _isLoadingProgress = true;
    _progressError = null;
    notifyListeners();

    try {
      final response = await _api.get('/levels/me');
      if (response is Map<String, dynamic>) {
        _myProgress = UserLevelProgressModel.fromApi(response);
      }
      _progressError = null;
    } on ApiException catch (e) {
      _progressError = e.message;
    } catch (e) {
      _progressError = 'Failed to load level progress';
    } finally {
      _isLoadingProgress = false;
      notifyListeners();
    }
  }

  /// Get a specific user's level by userId
  Future<UserLevelProgressModel?> getUserLevel(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return null;

    final cached = _userProgressByUserId[normalized];
    if (cached != null) {
      return cached;
    }

    final inFlight = _inFlightUserLevels[normalized];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _fetchUserLevel(normalized);
    _inFlightUserLevels[normalized] = request;
    try {
      return await request;
    } finally {
      _inFlightUserLevels.remove(normalized);
    }
  }

  Future<UserLevelProgressModel?> _fetchUserLevel(String userId) async {
    try {
      final response = await _api.get('/levels/user/$userId');
      if (response is Map<String, dynamic>) {
        final progress = UserLevelProgressModel.fromApi(response);
        final existing = _userProgressByUserId[userId];
        _userProgressByUserId[userId] = progress;
        if (existing?.currentLevel.id != progress.currentLevel.id) {
          notifyListeners();
        }
        return progress;
      }
    } on ApiException catch (e) {
      debugPrint('Failed to fetch user level: ${e.message}');
    } catch (e) {
      debugPrint('Failed to fetch user level: $e');
    }
    return null;
  }

  /// Manually trigger a level recalculation for the current user.
  ///
  /// The endpoint answers with `{levelChanged, previousLevel, currentLevel}`
  /// only, so the full progress (metrics, next level, progress bars) is
  /// re-fetched from `/levels/me` afterwards. Returns `true` when the
  /// recalculation itself succeeded; check [levelChanged] for the outcome.
  Future<bool> recalculateMyLevel() async {
    if (_isRecalculating) return false;

    _isRecalculating = true;
    _levelChanged = false;
    notifyListeners();

    try {
      final response = await _api.patch('/levels/me/recalculate');
      if (response is! Map) return false;

      _levelChanged = response['levelChanged'] == true;
      final currentLevel = _levelFromRaw(response['currentLevel']);

      // Wait for any fetch that started before the recalculation so its
      // stale result cannot overwrite the refreshed one.
      final pending = _inFlightProgress;
      if (pending != null) await pending;
      await fetchMyProgress();

      // If the refresh failed, at least reflect the confirmed level.
      final existing = _myProgress;
      if (_progressError != null && existing != null && currentLevel != null) {
        _myProgress = existing.copyWith(currentLevel: currentLevel);
      }
      return true;
    } on ApiException catch (e) {
      debugPrint('Failed to recalculate level: ${e.message}');
    } catch (e) {
      debugPrint('Failed to recalculate level: $e');
    } finally {
      _isRecalculating = false;
      notifyListeners();
    }
    return false;
  }

  static UserLevelModel? _levelFromRaw(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    return UserLevelModel.fromApi(json);
  }

  /// Get level by level number
  UserLevelModel? getLevelByNumber(int levelNumber) {
    try {
      return _allLevels.firstWhere((level) => level.level == levelNumber);
    } catch (_) {
      return null;
    }
  }

  /// Get the next level after a given level number
  UserLevelModel? getNextLevel(int currentLevelNumber) {
    final nextLevelNumber = currentLevelNumber + 1;
    return getLevelByNumber(nextLevelNumber);
  }

  /// Clear all cached data
  void clear() {
    _allLevels = [];
    _myProgress = null;
    _userProgressByUserId.clear();
    _inFlightUserLevels.clear();
    _levelsError = null;
    _progressError = null;
    _isLoadingLevels = false;
    _isLoadingProgress = false;
    _isRecalculating = false;
    _levelChanged = false;
    _inFlightProgress = null;
    notifyListeners();
  }

  /// Initialize the store by loading all levels and user progress
  Future<void> initialize() async {
    await Future.wait([
      fetchAllLevels(),
      fetchMyProgress(),
    ]);
  }
}
