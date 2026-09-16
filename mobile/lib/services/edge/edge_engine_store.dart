import 'package:blocnet/features/engagement/data/models/edge_feed_model.dart';
import 'package:blocnet/features/engagement/data/repositories/edge_engine_api_repository.dart';
import 'package:flutter/material.dart';

/// Edge decisions for the Home feed: the verdict chip on each card and the
/// score the feed ranks by. The weekly brief, the explain sheet and the
/// feedback call belonged to the Edge Engine page, which was cut.
class EdgeEngineStore extends ChangeNotifier {
  EdgeEngineStore({EdgeEngineApiRepository? repository})
      : _repository = repository ?? EdgeEngineApiRepository();

  final EdgeEngineApiRepository _repository;

  EdgeFeedResponse? _feed;
  bool _isFetching = false;
  String? _lastError;

  EdgeFeedResponse? get feed => _feed;
  bool get isFetching => _isFetching;
  String? get lastError => _lastError;
  List<EdgeDecision> get decisions => _feed?.items ?? const [];

  /// Loads the decision feed once; later calls are no-ops.
  Future<void> ensureFeed() async {
    if (_feed != null) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();
    try {
      _feed = await _repository.fetchFeed(limit: 30);
      _lastError = null;
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
}
