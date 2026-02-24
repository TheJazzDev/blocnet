import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/data/repositories/quests_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class QuestsStore extends ChangeNotifier {
  QuestsStore({QuestsApiRepository? repository})
      : _repository = repository ?? QuestsApiRepository();

  final QuestsApiRepository _repository;

  List<QuestModel> _allQuests = const [];
  List<UserQuestModel> _myQuests = const [];
  int _totalCount = 0;
  int _completedCount = 0;
  int _inProgressCount = 0;
  bool _isLoadingAll = false;
  bool _isLoadingMy = false;
  bool _isStarting = false;
  bool _isSubmitting = false;
  bool _isClaiming = false;
  String? _lastError;

  List<QuestModel> get allQuests => List.unmodifiable(_allQuests);
  List<UserQuestModel> get myQuests => List.unmodifiable(_myQuests);
  int get totalCount => _totalCount;
  int get completedCount => _completedCount;
  int get inProgressCount => _inProgressCount;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  bool get isStarting => _isStarting;
  bool get isSubmitting => _isSubmitting;
  bool get isClaiming => _isClaiming;
  String? get lastError => _lastError;

  bool get isBusy =>
      _isLoadingAll ||
      _isLoadingMy ||
      _isStarting ||
      _isSubmitting ||
      _isClaiming;

  int get pendingVerificationCount => _myQuests
      .where((q) => q.status == QuestStatus.pendingVerification)
      .length;
  int get notStartedCount => _allQuests.length - _myQuests.length;

  /// Get user quest IDs for quick lookup
  Set<String> get startedQuestIds =>
      _myQuests.map((uq) => uq.questId).toSet();

  /// Check if user has started a specific quest
  bool hasStarted(String questId) => startedQuestIds.contains(questId);

  /// Get user quest by quest ID
  UserQuestModel? getUserQuest(String questId) {
    try {
      return _myQuests.firstWhere((uq) => uq.questId == questId);
    } catch (_) {
      return null;
    }
  }

  /// Get quests by category
  List<QuestModel> getQuestsByCategory(BadgeCategory category) {
    return _allQuests.where((q) => q.category == category).toList();
  }

  /// Get quests by type
  List<QuestModel> getQuestsByType(QuestType type) {
    return _allQuests.where((q) => q.type == type).toList();
  }

  /// Get user quests by status
  List<UserQuestModel> getQuestsByStatus(QuestStatus status) {
    return _myQuests.where((uq) => uq.status == status).toList();
  }

  /// Get available quests (not started yet)
  List<QuestModel> getAvailableQuests() {
    return _allQuests
        .where((q) => !hasStarted(q.id) && q.isActive && !q.isExpired)
        .toList();
  }

  /// Get completed quests
  List<UserQuestModel> getCompletedQuests() {
    return getQuestsByStatus(QuestStatus.completed);
  }

  /// Get in-progress quests
  List<UserQuestModel> getInProgressQuests() {
    return getQuestsByStatus(QuestStatus.inProgress);
  }

  /// Get pending verification quests
  List<UserQuestModel> getPendingQuests() {
    return getQuestsByStatus(QuestStatus.pendingVerification);
  }

  Future<void> loadAllQuests({bool force = false}) async {
    if (_isLoadingAll) return;
    if (!force && _allQuests.isNotEmpty) return;

    _isLoadingAll = true;
    notifyListeners();

    try {
      _allQuests = await _repository.fetchAllQuests();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      _allQuests = const [];
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> loadMyQuests({bool force = false, String? status}) async {
    if (_isLoadingMy) return;
    if (!force && _myQuests.isNotEmpty && status == null) return;

    _isLoadingMy = true;
    notifyListeners();

    try {
      final response = await _repository.fetchMyQuests(status: status);
      _myQuests = response?.quests ?? const [];
      _totalCount = response?.totalCount ?? 0;
      _completedCount = response?.completedCount ?? 0;
      _inProgressCount = response?.inProgressCount ?? 0;
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      _myQuests = const [];
    } finally {
      _isLoadingMy = false;
      notifyListeners();
    }
  }

  Future<bool> startQuest(String questSlug) async {
    if (_isStarting) return false;

    // Check if quest exists and is active
    final quest = _allQuests.cast<QuestModel?>().firstWhere(
          (q) => q?.slug == questSlug,
          orElse: () => null,
        );

    if (quest == null) {
      _lastError = 'Quest not found';
      notifyListeners();
      return false;
    }

    if (!quest.isActive || quest.isExpired) {
      _lastError = 'This quest is no longer available';
      notifyListeners();
      return false;
    }

    if (hasStarted(quest.id)) {
      _lastError = 'You have already started this quest';
      notifyListeners();
      return false;
    }

    _isStarting = true;
    notifyListeners();

    try {
      await _repository.startQuest(questSlug);

      // Refresh user quests to get the new quest
      await loadMyQuests(force: true);
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = describeError(error);
      return false;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<QuestSubmissionModel?> submitQuestProof({
    required String questSlug,
    String? proofUrl,
    String? proofText,
    String? screenshot,
  }) async {
    if (_isSubmitting) return null;

    // Validate that at least one proof is provided
    if (proofUrl == null && proofText == null && screenshot == null) {
      _lastError = 'Please provide at least one form of proof';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final submission = await _repository.submitQuestProof(
        questSlug: questSlug,
        proofUrl: proofUrl,
        proofText: proofText,
        screenshot: screenshot,
      );

      // Refresh user quests to update status
      await loadMyQuests(force: true);
      _lastError = null;
      return submission;
    } catch (error) {
      _lastError = describeError(error);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> claimQuestReward(String questSlug) async {
    if (_isClaiming) return false;

    // Find the quest
    final quest = _allQuests.cast<QuestModel?>().firstWhere(
          (q) => q?.slug == questSlug,
          orElse: () => null,
        );

    if (quest == null) {
      _lastError = 'Quest not found';
      notifyListeners();
      return false;
    }

    // Check if quest requires manual verification
    if (quest.requiresManualVerification) {
      _lastError = 'This quest requires manual verification. Please submit proof.';
      notifyListeners();
      return false;
    }

    // Check if user has started this quest
    final userQuest = getUserQuest(quest.id);
    if (userQuest == null) {
      _lastError = 'You have not started this quest';
      notifyListeners();
      return false;
    }

    // Check if already completed
    if (userQuest.status == QuestStatus.completed) {
      _lastError = 'You have already claimed this reward';
      notifyListeners();
      return false;
    }

    _isClaiming = true;
    notifyListeners();

    try {
      await _repository.claimQuestReward(questSlug);

      // Refresh user quests to update completion status
      await loadMyQuests(force: true);
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = describeError(error);
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadAllQuests(force: true),
      loadMyQuests(force: true),
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
