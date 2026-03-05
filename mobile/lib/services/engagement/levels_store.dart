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
  String? _levelsError;
  String? _progressError;
  final Map<String, UserLevelProgressModel> _userProgressByUserId = {};
  final Map<String, Future<UserLevelProgressModel?>> _inFlightUserLevels = {};

  List<UserLevelModel> get allLevels => _allLevels;
  UserLevelProgressModel? get myProgress => _myProgress;
  bool get isLoadingLevels => _isLoadingLevels;
  bool get isLoadingProgress => _isLoadingProgress;
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

  /// Fetch the current user's level progress
  Future<void> fetchMyProgress() async {
    if (_isLoadingProgress) return;

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

  /// Manually trigger a level recalculation for the current user
  Future<bool> recalculateMyLevel() async {
    try {
      final response = await _api.patch('/levels/me/recalculate');
      if (response is Map<String, dynamic>) {
        _myProgress = UserLevelProgressModel.fromApi(response);
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      debugPrint('Failed to recalculate level: ${e.message}');
    } catch (e) {
      debugPrint('Failed to recalculate level: $e');
    }
    return false;
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
