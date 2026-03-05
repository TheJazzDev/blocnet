import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/edge_explain_model.dart';
import 'package:blocnet/features/engagement/data/models/edge_feed_model.dart';
import 'package:blocnet/features/engagement/data/repositories/edge_engine_api_repository.dart';
import 'package:flutter/material.dart';

class EdgeEngineStore extends ChangeNotifier {
  EdgeEngineStore({EdgeEngineApiRepository? repository})
      : _repository = repository ?? EdgeEngineApiRepository();

  final EdgeEngineApiRepository _repository;

  EdgeFeedResponse? _feed;
  EdgeBriefResponse? _brief;
  EdgeExplainResponse? _activeExplain;
  bool _isFetching = false;
  bool _isFetchingExplain = false;
  bool _isSendingFeedback = false;
  String? _lastError;

  EdgeFeedResponse? get feed => _feed;
  EdgeBriefResponse? get brief => _brief;
  EdgeExplainResponse? get activeExplain => _activeExplain;
  bool get isFetching => _isFetching;
  bool get isFetchingExplain => _isFetchingExplain;
  bool get isSendingFeedback => _isSendingFeedback;
  String? get lastError => _lastError;
  List<EdgeDecision> get decisions => _feed?.items ?? const [];

  void hydrateBrief(EdgeBriefResponse? brief, {bool notify = true}) {
    if (brief == null) return;
    _brief = brief;
    _lastError = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> fetchOnce() async {
    if ((_feed != null && _brief != null) || _isFetching) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isFetching) return;

    _isFetching = true;
    _lastError = null;
    notifyListeners();

    try {
      final responses = await Future.wait([
        _repository.fetchFeed(limit: 30),
        _repository.fetchBrief(windowDays: 7),
      ]);

      _feed = responses[0] as EdgeFeedResponse?;
      _brief = responses[1] as EdgeBriefResponse?;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  double? edgeScoreForUpdate(String updateId) {
    final decision = decisionForUpdate(updateId);
    return decision?.edgeScore;
  }

  EdgeDecision? decisionForUpdate(String updateId) {
    for (final decision in decisions) {
      if (decision.update.id == updateId) {
        return decision;
      }
    }
    return null;
  }

  Future<EdgeExplainResponse?> fetchExplain(String decisionId) async {
    if (_isFetchingExplain) return _activeExplain;

    _isFetchingExplain = true;
    _lastError = null;
    notifyListeners();
    try {
      _activeExplain = await _repository.fetchExplain(decisionId);
      return _activeExplain;
    } catch (error) {
      _lastError = error.toString();
      return null;
    } finally {
      _isFetchingExplain = false;
      notifyListeners();
    }
  }

  Future<bool> sendFeedback({
    required String decisionId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    if (_isSendingFeedback) return false;

    _isSendingFeedback = true;
    notifyListeners();
    try {
      final ok = await _repository.sendFeedback(
        decisionId: decisionId,
        action: action,
        context: context,
      );
      if (ok) {
        _lastError = null;
      }
      return ok;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSendingFeedback = false;
      notifyListeners();
    }
  }
}
