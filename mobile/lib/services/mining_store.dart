import 'dart:convert';

import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class MiningStore extends ChangeNotifier {
  MiningStore({MiningApiRepository? repository})
      : _repository = repository ?? MiningApiRepository();

  final MiningApiRepository _repository;

  MiningSnapshot? _snapshot;
  List<DownlineMember> _downline = const [];
  List<MiningLeaderboardEntry> _leaderboard = const [];
  bool _isLoadingSnapshot = false;
  bool _isLoadingDownline = false;
  bool _isLoadingLeaderboard = false;
  bool _isStarting = false;
  bool _isClaiming = false;
  bool _isBindingReferral = false;
  String? _lastError;

  MiningSnapshot? get snapshot => _snapshot;
  List<DownlineMember> get downline => List.unmodifiable(_downline);
  List<MiningLeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  bool get isLoadingSnapshot => _isLoadingSnapshot;
  bool get isLoadingDownline => _isLoadingDownline;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get isStarting => _isStarting;
  bool get isClaiming => _isClaiming;
  bool get isBindingReferral => _isBindingReferral;
  String? get lastError => _lastError;

  bool get isBusy =>
      _isLoadingSnapshot ||
      _isLoadingDownline ||
      _isLoadingLeaderboard ||
      _isStarting ||
      _isClaiming ||
      _isBindingReferral;

  Future<void> loadSnapshot({bool force = false}) async {
    if (_isLoadingSnapshot) return;
    if (!force && _snapshot != null) return;

    _isLoadingSnapshot = true;
    notifyListeners();

    try {
      _snapshot = await _repository.fetchMiningSnapshot();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingSnapshot = false;
      notifyListeners();
    }
  }

  Future<void> loadDownline({bool force = false}) async {
    if (_isLoadingDownline) return;
    if (!force && _downline.isNotEmpty) return;

    _isLoadingDownline = true;
    notifyListeners();

    try {
      final response = await _repository.fetchDownline(limit: 30, offset: 0);
      _downline = response?.data ?? const [];
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingDownline = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadSnapshot(force: true),
      loadDownline(force: true),
      loadLeaderboard(force: true),
    ]);
  }

  Future<void> loadLeaderboard({bool force = false}) async {
    if (_isLoadingLeaderboard) return;
    if (!force && _leaderboard.isNotEmpty) return;

    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final response = await _repository.fetchLeaderboard(limit: 20, offset: 0);
      _leaderboard = response?.data ?? const [];
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> startMining() async {
    if (_isStarting) return;

    _isStarting = true;
    notifyListeners();

    try {
      await _repository.startMining();
      await refreshAll();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> claimMining() async {
    if (_isClaiming) return;

    _isClaiming = true;
    notifyListeners();

    try {
      await _repository.claimMining();
      await refreshAll();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  Future<ReferralValidation?> validateReferralCode(String code) {
    return _repository.validateReferralCode(code);
  }

  Future<void> bindReferralCode(String code) async {
    if (_isBindingReferral) return;

    _isBindingReferral = true;
    notifyListeners();

    try {
      await _repository.bindReferralCode(code);
      await refreshAll();
      _lastError = null;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isBindingReferral = false;
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
          // no-op
        }
      }

      if (error.statusCode == 409 && body?.contains('claim_required') == true) {
        return 'Claim your completed cycle before starting a new one.';
      }
      if (error.statusCode == 409 && body?.contains('not_claimable') == true) {
        return 'This cycle is still running. Claim becomes available at cycle end.';
      }

      return error.message;
    }

    return error.toString();
  }

  void clear() {
    _snapshot = null;
    _downline = const [];
    _leaderboard = const [];
    _lastError = null;
    notifyListeners();
  }
}
