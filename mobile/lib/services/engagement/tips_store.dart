import 'dart:convert';

import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/data/repositories/tip_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class TipsStore extends ChangeNotifier {
  TipsStore({TipApiRepository? repository})
      : _repository = repository ?? TipApiRepository();

  final TipApiRepository _repository;

  TipOverview? _overview;
  List<TipTransaction> _history = const [];
  List<TipTransaction> _sentHistory = const [];
  List<TipTransaction> _receivedHistory = const [];
  int _historyTotal = 0;
  int _sentHistoryTotal = 0;
  int _receivedHistoryTotal = 0;
  bool _isLoadingOverview = false;
  bool _isLoadingHistory = false;
  bool _isLoadingSentHistory = false;
  bool _isLoadingReceivedHistory = false;
  bool _isSending = false;
  String? _lastError;
  String? _boundUserId;

  TipOverview? get overview => _overview;
  List<TipTransaction> get history => List.unmodifiable(_history);
  List<TipTransaction> get sentHistory => List.unmodifiable(_sentHistory);
  List<TipTransaction> get receivedHistory =>
      List.unmodifiable(_receivedHistory);
  int get historyTotal => _historyTotal;
  int get sentHistoryTotal => _sentHistoryTotal;
  int get receivedHistoryTotal => _receivedHistoryTotal;
  bool get isLoadingOverview => _isLoadingOverview;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingSentHistory => _isLoadingSentHistory;
  bool get isLoadingReceivedHistory => _isLoadingReceivedHistory;
  bool get isSending => _isSending;
  String? get lastError => _lastError;
  String get profileTipsSentValue {
    final summary = _overview?.sentSummary;
    if (summary == null) {
      return _sentHistoryTotal > 0 ? _sentHistoryTotal.toString() : '0';
    }
    return summary.amount;
  }

  void ensureUserScope(String? userId) {
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    if (_boundUserId == normalized) {
      return;
    }

    _boundUserId = normalized;
    _resetState(notify: true);
  }

  Future<void> loadOverview({bool force = false}) async {
    if (_isLoadingOverview) return;
    if (!force && _overview != null) return;

    _isLoadingOverview = true;
    notifyListeners();
    try {
      _overview = await _repository.fetchOverview();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingOverview = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory({
    bool force = false,
    int limit = 30,
    int offset = 0,
    String direction = 'all',
    String? currencyCode,
  }) async {
    if (_isLoadingHistory) return;
    if (!force && _history.isNotEmpty && offset == 0) return;

    _isLoadingHistory = true;
    notifyListeners();
    try {
      final response = await _repository.fetchHistory(
        limit: limit,
        offset: offset,
        direction: direction,
        currencyCode: currencyCode,
      );
      _history = response?.data ?? const [];
      _historyTotal = response?.total ?? 0;
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadSentHistory({
    bool force = false,
    int limit = 50,
    int offset = 0,
    String? currencyCode,
  }) async {
    if (_isLoadingSentHistory) return;
    if (!force && _sentHistory.isNotEmpty && offset == 0) return;

    _isLoadingSentHistory = true;
    notifyListeners();
    try {
      final response = await _repository.fetchHistory(
        limit: limit,
        offset: offset,
        direction: 'sent',
        currencyCode: currencyCode,
      );
      _sentHistory = response?.data ?? const [];
      _sentHistoryTotal = response?.total ?? 0;
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingSentHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadReceivedHistory({
    bool force = false,
    int limit = 50,
    int offset = 0,
    String? currencyCode,
  }) async {
    if (_isLoadingReceivedHistory) return;
    if (!force && _receivedHistory.isNotEmpty && offset == 0) return;

    _isLoadingReceivedHistory = true;
    notifyListeners();
    try {
      final response = await _repository.fetchHistory(
        limit: limit,
        offset: offset,
        direction: 'received',
        currencyCode: currencyCode,
      );
      _receivedHistory = response?.data ?? const [];
      _receivedHistoryTotal = response?.total ?? 0;
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingReceivedHistory = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadOverview(force: true),
      loadHistory(force: true),
      loadSentHistory(force: true),
      loadReceivedHistory(force: true),
    ]);
  }

  Future<TipTransaction?> sendTip({
    required String amount,
    String? toUserId,
    String? toUsername,
    String? currencyCode,
    String? note,
    String? contextType,
    String? contextId,
    String? idempotencyKey,
  }) async {
    if (_isSending) return null;
    _isSending = true;
    notifyListeners();

    try {
      final created = await _repository.sendTip(
        amount: amount,
        toUserId: toUserId,
        toUsername: toUsername,
        currencyCode: currencyCode,
        note: note,
        contextType: contextType,
        contextId: contextId,
        idempotencyKey: idempotencyKey,
      );
      _lastError = null;
      if (created != null) {
        _applyOptimisticSentTransaction(created);
      }
      await refreshAll();
      return created;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  String describeError(Object error) {
    if (error is ApiException) {
      final body = error.responseBody?.trim();
      if (body != null && body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map<String, dynamic>) {
            final message = parsed['message']?.toString();
            if (message != null && message.isNotEmpty) {
              return message;
            }
          }
        } catch (_) {
          // fall through
        }
      }
      if (error.statusCode != null) {
        return 'Request failed (${error.statusCode})';
      }
      return error.message;
    }
    return error.toString();
  }

  void clear() {
    _boundUserId = null;
    _resetState(notify: true);
  }

  void _resetState({required bool notify}) {
    _overview = null;
    _history = const [];
    _sentHistory = const [];
    _receivedHistory = const [];
    _historyTotal = 0;
    _sentHistoryTotal = 0;
    _receivedHistoryTotal = 0;
    _lastError = null;
    _isLoadingOverview = false;
    _isLoadingHistory = false;
    _isLoadingSentHistory = false;
    _isLoadingReceivedHistory = false;
    _isSending = false;
    if (notify) {
      notifyListeners();
    }
  }

  void _applyOptimisticSentTransaction(TipTransaction created) {
    final existsInSent = _sentHistory.any((row) => row.id == created.id);
    final existsInHistory = _history.any((row) => row.id == created.id);

    if (!existsInSent) {
      _sentHistory = <TipTransaction>[created, ..._sentHistory];
      _sentHistoryTotal += 1;
    }

    if (!existsInHistory) {
      _history = <TipTransaction>[created, ..._history];
      _historyTotal += 1;
    }

    notifyListeners();
  }
}
