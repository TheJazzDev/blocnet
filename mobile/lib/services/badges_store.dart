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
  BadgeModel? get displayBadge => _primaryBadge ?? _highestEarnedBadge();
  int get totalBadgeCount => _totalBadgeCount;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  bool get isSettingPrimary => _isSettingPrimary;
  String? get lastError => _lastError;

  bool get isBusy => _isLoadingAll || _isLoadingMy || _isSettingPrimary;

  int get earnedBadgeCount => _myBadges.length;
  int get unearnedBadgeCount => _allBadges.length - earnedBadgeCount;

  /// Get earned badge IDs for quick lookup
  Set<String> get earnedBadgeIds => _myBadges.map((ub) => ub.badgeId).toSet();

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

      // Update local state safely even if all badges cache is stale/empty.
      BadgeModel? resolvedPrimary;
      for (final badge in _allBadges) {
        if (badge.id == badgeId) {
          resolvedPrimary = badge;
          break;
        }
      }
      if (resolvedPrimary == null) {
        for (final userBadge in _myBadges) {
          if (userBadge.badge.id == badgeId) {
            resolvedPrimary = userBadge.badge;
            break;
          }
        }
      }
      _primaryBadge = resolvedPrimary;
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

  BadgeModel? _highestEarnedBadge() {
    if (_myBadges.isEmpty) return null;

    final sorted = _myBadges
        .map((entry) => entry.badge)
        .where((badge) => badge.id.isNotEmpty)
        .toList()
      ..sort(_compareBadgePriority);

    if (sorted.isEmpty) return null;
    return sorted.first;
  }

  int _compareBadgePriority(BadgeModel left, BadgeModel right) {
    final rarityDelta =
        _rarityRank(right.rarity).compareTo(_rarityRank(left.rarity));
    if (rarityDelta != 0) return rarityDelta;

    final pointsDelta =
        right.pointsRequirement.compareTo(left.pointsRequirement);
    if (pointsDelta != 0) return pointsDelta;

    final sortOrderDelta = left.sortOrder.compareTo(right.sortOrder);
    if (sortOrderDelta != 0) return sortOrderDelta;

    return right.createdAt.compareTo(left.createdAt);
  }

  int _rarityRank(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.legendary:
        return 4;
      case BadgeRarity.epic:
        return 3;
      case BadgeRarity.rare:
        return 2;
      case BadgeRarity.common:
        return 1;
    }
  }

  static String describeError(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
