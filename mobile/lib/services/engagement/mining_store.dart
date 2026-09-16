import 'package:blocnet/features/mining/data/mining_error_copy.dart';
import 'package:blocnet/features/mining/data/mining_expiry_copy.dart';
import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:flutter/foundation.dart';

part 'mining_store_data.part.dart';

/// Mine tab store: cached data and reads come from [_MiningStoreData]; this
/// class adds what a member does (start, claim, bind a referral) and sign-out.
class MiningStore extends _MiningStoreData {
  MiningStore({super.repository, super.deviceClock});

  Future<MiningStartResult?> startMining() async {
    if (_isStarting) return null;

    final generation = _generation;
    _isStarting = true;
    _actionError = null;
    notifyListeners();

    try {
      final result = await _repository.startMining();
      if (generation != _generation) return null;
      // Start reconciles too: older cycles can be forfeited on the way in, and
      // the member is owed that news.
      _forfeitNotice = result.hasExpiredCycles
          ? MiningExpiryCopy.startForfeited(result)
          : null;
      await refreshAll();
      return result;
    } catch (error) {
      if (generation == _generation) _actionError = describeError(error);
      rethrow;
    } finally {
      if (generation == _generation) {
        _isStarting = false;
        notifyListeners();
      }
    }
  }

  /// Claims the completed cycle.
  ///
  /// `POST /mining/claim` answers 200 whether it paid out or forfeited an
  /// expired cycle, so "no exception thrown" is not success. The parsed result
  /// is returned and mirrored on [lastClaimResult]; a forfeit sets
  /// [forfeitNotice] instead of [actionError].
  Future<MiningClaimResult?> claimMining() async {
    if (_isClaiming) return null;

    final generation = _generation;
    _isClaiming = true;
    _actionError = null;
    notifyListeners();

    try {
      final result = await _repository.claimMining();
      if (generation != _generation) return null;
      _lastClaimResult = result;
      _forfeitNotice = result.isClaimed ? null : _describeForfeit(result);

      // Reconcile before refreshing: the response's balance is authoritative
      // and may be LOWER than the cached one (forfeited checkpoints stop
      // counting), so apply it wholesale.
      _applyAuthoritativeClaimState(result);

      await refreshAll();
      return result;
    } catch (error) {
      if (generation == _generation) _actionError = describeError(error);
      rethrow;
    } finally {
      if (generation == _generation) {
        _isClaiming = false;
        notifyListeners();
      }
    }
  }

  String? _describeForfeit(MiningClaimResult result) {
    // Unreadable body or missing status: say nothing rather than guess. The
    // forced refresh shows the real state.
    if (!result.isExpired) return null;

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

    final generation = _generation;
    _isBindingReferral = true;
    _actionError = null;
    notifyListeners();

    try {
      await _repository.bindReferralCode(code);
      if (generation != _generation) return;
      await refreshAll();
    } catch (error) {
      if (generation == _generation) _actionError = describeError(error);
      rethrow;
    } finally {
      if (generation == _generation) {
        _isBindingReferral = false;
        notifyListeners();
      }
    }
  }

  void clearActionError() {
    if (_actionError == null) return;
    _actionError = null;
    notifyListeners();
  }

  /// Drops everything cached for the signed-in account. Called on sign-out so
  /// the next account never sees the previous one's balance or cycle.
  void clear() {
    _generation++;
    _snapshot = null;
    _referralSummary = null;
    _referralError = null;
    _downline = const [];
    _leaderboard = const [];
    _snapshotError = null;
    _leaderboardError = null;
    _downlineError = null;
    _actionError = null;
    _lastClaimResult = null;
    _forfeitNotice = null;
    _clockOffset = Duration.zero;
    _cycleEndRefetchedFor = null;
    _isLoadingSnapshot = false;
    _isLoadingReferral = false;
    _isLoadingDownline = false;
    _isLoadingLeaderboard = false;
    _isStarting = false;
    _isClaiming = false;
    _isBindingReferral = false;
    notifyListeners();
  }
}
