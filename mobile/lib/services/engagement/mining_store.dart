import 'dart:convert';

import 'package:blocnet/features/mining/data/mining_expiry_copy.dart';
import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class MiningStore extends ChangeNotifier {
  MiningStore({MiningApiRepository? repository})
      : _repository = repository ?? MiningApiRepository();

  final MiningApiRepository _repository;

  MiningSnapshot? _snapshot;
  ReferralSummaryModel? _referralSummary;
  List<DownlineMember> _downline = const [];
  List<MiningLeaderboardEntry> _leaderboard = const [];
  bool _isLoadingSnapshot = false;
  bool _isLoadingReferral = false;
  bool _isLoadingDownline = false;
  bool _isLoadingLeaderboard = false;
  bool _isStarting = false;
  bool _isClaiming = false;
  bool _isBindingReferral = false;
  String? _lastError;
  String? _referralError;
  MiningClaimResult? _lastClaimResult;
  String? _forfeitNotice;

  MiningSnapshot? get snapshot => _snapshot;

  /// Referral totals from `GET /referrals/me`. Falls back to the referral
  /// block embedded in the mining snapshot when the dedicated call has not
  /// resolved yet, so callers always get the freshest data available.
  ReferralSummaryModel? get referralSummary =>
      _referralSummary ?? _snapshot?.referral;
  List<DownlineMember> get downline => List.unmodifiable(_downline);
  List<MiningLeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  bool get isLoadingSnapshot => _isLoadingSnapshot;
  bool get isLoadingReferral => _isLoadingReferral;
  bool get isLoadingDownline => _isLoadingDownline;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get isStarting => _isStarting;
  bool get isClaiming => _isClaiming;
  bool get isBindingReferral => _isBindingReferral;
  String? get lastError => _lastError;
  String? get referralError => _referralError;

  /// Parsed body of the most recent claim. A claim that forfeited is reported
  /// here with `isExpired`, not through [lastError] — it is an outcome, not a
  /// crash.
  MiningClaimResult? get lastClaimResult => _lastClaimResult;

  /// Plain-English explanation of a cycle that expired unclaimed, set by
  /// [claimMining] or [startMining]. Cleared by [clearForfeitNotice] once the
  /// UI has shown it.
  String? get forfeitNotice => _forfeitNotice;

  void clearForfeitNotice() {
    if (_forfeitNotice == null) return;
    _forfeitNotice = null;
    notifyListeners();
  }

  bool get isBusy =>
      _isLoadingSnapshot ||
      _isLoadingReferral ||
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

  Future<void> loadReferralSummary({bool force = false}) async {
    if (_isLoadingReferral) return;
    if (!force && _referralSummary != null) return;

    _isLoadingReferral = true;
    notifyListeners();

    try {
      final summary = await _repository.fetchReferralSummary();
      if (summary != null) {
        _referralSummary = summary;
      }
      _referralError = null;
    } catch (error) {
      _referralError = describeError(error);
    } finally {
      _isLoadingReferral = false;
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
      loadReferralSummary(force: true),
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

  Future<MiningStartResult?> startMining() async {
    if (_isStarting) return null;

    _isStarting = true;
    notifyListeners();

    try {
      final result = await _repository.startMining();
      // Start reconciles too: older cycles can be forfeited on the way in, and
      // the user is owed that news.
      _forfeitNotice = result.hasExpiredCycles
          ? MiningExpiryCopy.startForfeited(result)
          : null;
      await refreshAll();
      _lastError = null;
      return result;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  /// Claims the completed cycle.
  ///
  /// `POST /mining/claim` answers 200 whether it paid out or forfeited an
  /// expired cycle, so "no exception thrown" is not success. The parsed result
  /// is returned and mirrored on [lastClaimResult]; a forfeit sets
  /// [forfeitNotice] instead of [lastError].
  Future<MiningClaimResult?> claimMining() async {
    if (_isClaiming) return null;

    _isClaiming = true;
    notifyListeners();

    try {
      final result = await _repository.claimMining();
      _lastClaimResult = result;
      _forfeitNotice =
          result.isClaimed ? null : _describeForfeit(result);

      // Reconcile before refreshing: the response's balance is authoritative
      // and may be LOWER than the cached one (forfeited checkpoints stop
      // counting), so apply it wholesale rather than leaving a stale higher
      // number on screen while the refresh is in flight.
      _applyAuthoritativeClaimState(result);

      await refreshAll();
      _lastError = null;
      return result;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  String? _describeForfeit(MiningClaimResult result) {
    if (result.status == 'unknown') {
      // Unreadable body: say nothing rather than claim a payout that may not
      // have happened. The forced refresh below shows the real state.
      return null;
    }

    return MiningExpiryCopy.claimExpired(
      result,
      claimWindowHours: _snapshot?.config.claimWindowHours,
    );
  }

  /// Overwrites the cached balance and session with the values the claim
  /// response reported. Sub-objects are replaced, never field-merged, so a
  /// value that went *down* survives.
  void _applyAuthoritativeClaimState(MiningClaimResult result) {
    final current = _snapshot;
    if (current == null) return;
    if (result.balance == null && result.nextSession == null) return;

    _snapshot = current.copyWith(
      balance: result.balance,
      session: result.nextSession,
      // `expiredCycles` arrives oldest-first; the snapshot field means "most
      // recent", so take the last one.
      lastExpiredCycle:
          result.expiredCycles.isEmpty ? null : result.expiredCycles.last,
    );
    notifyListeners();
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
        return 'Nothing to claim yet — this cycle pays out once it finishes.';
      }
      if (body?.contains('claim_window_expired') == true) {
        return 'That cycle expired before it was claimed, so its points were '
            'forfeited. Start a new cycle to keep mining.';
      }

      return error.message;
    }

    return error.toString();
  }

  void clear() {
    _snapshot = null;
    _referralSummary = null;
    _referralError = null;
    _downline = const [];
    _leaderboard = const [];
    _lastError = null;
    _lastClaimResult = null;
    _forfeitNotice = null;
    notifyListeners();
  }
}
