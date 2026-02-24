import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/data/repositories/badges_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class BadgesStore extends ChangeNotifier {
  BadgesStore({BadgesApiRepository? repository})
      : _repository = repository ?? BadgesApiRepository();

  final BadgesApiRepository _repository;

  List<BadgeModel> _allBadges = const [];
  List<UserBadgeModel> _myBadges = const [];
  BadgeModel? _primaryBadge;
  int _totalBadgeCount = 0;
  bool _isLoadingAll = false;
  bool _isLoadingMy = false;
  bool _isSettingPrimary = false;
  String? _lastError;

  List<BadgeModel> get allBadges => List.unmodifiable(_allBadges);
  List<UserBadgeModel> get myBadges => List.unmodifiable(_myBadges);
  BadgeModel? get primaryBadge => _primaryBadge;
  int get totalBadgeCount => _totalBadgeCount;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  bool get isSettingPrimary => _isSettingPrimary;
  String? get lastError => _lastError;

  bool get isBusy => _isLoadingAll || _isLoadingMy || _isSettingPrimary;

  int get earnedBadgeCount => _myBadges.length;
  int get unearnedBadgeCount => _allBadges.length - earnedBadgeCount;

  /// Get earned badge IDs for quick lookup
  Set<String> get earnedBadgeIds =>
      _myBadges.map((ub) => ub.badgeId).toSet();

  /// Check if user has earned a specific badge
  bool hasBadge(String badgeId) => earnedBadgeIds.contains(badgeId);

  /// Get badges by category
  List<BadgeModel> getBadgesByCategory(BadgeCategory category) {
    return _allBadges.where((b) => b.category == category).toList();
  }

  /// Get earned badges by category
  List<UserBadgeModel> getEarnedBadgesByCategory(BadgeCategory category) {
    return _myBadges.where((ub) => ub.badge.category == category).toList();
  }

  /// Get badges by rarity
  List<BadgeModel> getBadgesByRarity(BadgeRarity rarity) {
    return _allBadges.where((b) => b.rarity == rarity).toList();
  }

  Future<void> loadAllBadges({bool force = false}) async {
    if (_isLoadingAll) return;
    if (!force && _allBadges.isNotEmpty) return;

    _isLoadingAll = true;
    notifyListeners();

    try {
      _allBadges = await _repository.fetchAllBadges();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      _allBadges = const [];
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> loadMyBadges({bool force = false}) async {
    if (_isLoadingMy) return;
    if (!force && _myBadges.isNotEmpty) return;

    _isLoadingMy = true;
    notifyListeners();

    try {
      final response = await _repository.fetchMyBadges();
      _myBadges = response?.badges ?? const [];
      _primaryBadge = response?.primaryBadge;
      _totalBadgeCount = response?.totalCount ?? 0;
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      _myBadges = const [];
      _primaryBadge = null;
    } finally {
      _isLoadingMy = false;
      notifyListeners();
    }
  }

  Future<void> loadUserBadges(String userId) async {
    try {
      await _repository.fetchUserBadges(userId);
      // Store in a separate variable if needed for viewing other users' badges
      // For now we only track current user's badges
    } catch (error) {
      _lastError = describeError(error);
    }
  }

  Future<bool> setPrimaryBadge(String badgeId) async {
    if (_isSettingPrimary) return false;

    // Check if user has earned this badge
    if (!hasBadge(badgeId)) {
      _lastError = 'You have not earned this badge';
      notifyListeners();
      return false;
    }

    _isSettingPrimary = true;
    notifyListeners();

    try {
      await _repository.setPrimaryBadge(badgeId);

      // Update local state
      _primaryBadge = _allBadges.firstWhere((b) => b.id == badgeId);
      _lastError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _lastError = describeError(error);
      notifyListeners();
      return false;
    } finally {
      _isSettingPrimary = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadAllBadges(force: true),
      loadMyBadges(force: true),
    ]);
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  static String describeError(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
