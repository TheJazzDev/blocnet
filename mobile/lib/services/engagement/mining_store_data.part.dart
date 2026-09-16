part of 'mining_store.dart';

/// Cached Mine data and the read requests behind it. Member actions live on
/// [MiningStore]. Each request owns its own error (F-54): a failed leaderboard
/// must not wipe, or impersonate, a snapshot failure.
abstract class _MiningStoreData extends ChangeNotifier {
  _MiningStoreData({
    MiningApiRepository? repository,
    DateTime Function()? deviceClock,
    MineLocalCache? localCache,
  })  : _repository = repository ?? MiningApiRepository(),
        _deviceClock = deviceClock ?? DateTime.now,
        _localCache = localCache ?? const MineLocalCache();

  /// Rows per leaderboard page.
  static const int leaderboardPageSize = 10;

  final MiningApiRepository _repository;
  final DateTime Function() _deviceClock;
  final MineLocalCache _localCache;

  MiningSnapshot? _snapshot;
  ReferralSummaryModel? _referralSummary;
  List<DownlineMember> _downline = const [];
  List<MiningLeaderboardEntry> _leaderboard = const [];
  List<MiningLeaderboardEntry> _leaderboardTop = const [];
  MiningLeaderboardEntry? _leaderboardMe;
  int _leaderboardPage = 1;
  int _leaderboardTotal = 0;
  int? _cachedBalance;
  bool _isLoadingSnapshot = false;
  bool _isLoadingReferral = false;
  bool _isLoadingDownline = false;
  bool _isLoadingLeaderboard = false;
  bool _isStarting = false;
  bool _isClaiming = false;
  bool _isBindingReferral = false;
  String? _snapshotError;
  String? _leaderboardError;
  String? _downlineError;
  String? _actionError;
  String? _referralError;
  MiningClaimResult? _lastClaimResult;
  String? _forfeitNotice;
  Duration _clockOffset = Duration.zero;
  String? _cycleEndRefetchedFor;

  /// Bumped by [clear]. A response that lands after sign-out belongs to the
  /// previous account and is dropped.
  int _generation = 0;

  MiningSnapshot? get snapshot => _snapshot;

  /// Referral totals from `GET /referrals/me`, falling back to the block
  /// embedded in the mining snapshot until the dedicated call resolves.
  ReferralSummaryModel? get referralSummary =>
      _referralSummary ?? _snapshot?.referral;
  List<DownlineMember> get downline => List.unmodifiable(_downline);

  /// The leaderboard page last loaded, [leaderboardPageSize] rows at most.
  List<MiningLeaderboardEntry> get leaderboard =>
      List.unmodifiable(_leaderboard);

  /// The top three, from the last page-one load. The Mine preview reads this
  /// so paging the full board does not change it.
  List<MiningLeaderboardEntry> get leaderboardTop =>
      List.unmodifiable(_leaderboardTop);

  /// The member's own row, or null when unranked or not sent.
  MiningLeaderboardEntry? get leaderboardMe => _leaderboardMe;
  int get leaderboardPage => _leaderboardPage;
  int get leaderboardPageCount {
    if (_leaderboardTotal <= 0) return 1;
    return (_leaderboardTotal + leaderboardPageSize - 1) ~/ leaderboardPageSize;
  }

  /// The live balance, else the one this device last saw. Shown on the
  /// couldn't-load screen so a failure does not blank what the member owns.
  int? get lastKnownBalance =>
      _snapshot?.balance.claimedTotalPoints ?? _cachedBalance;
  bool get isLoadingSnapshot => _isLoadingSnapshot;
  bool get isLoadingReferral => _isLoadingReferral;
  bool get isLoadingDownline => _isLoadingDownline;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get isStarting => _isStarting;
  bool get isClaiming => _isClaiming;
  bool get isBindingReferral => _isBindingReferral;

  /// Last failure of `GET /mining/me`. With no snapshot cached, the hero shows
  /// this with a retry instead of a made-up idle card (F-53).
  String? get snapshotError => _snapshotError;
  String? get leaderboardError => _leaderboardError;
  String? get downlineError => _downlineError;

  /// Last failure of a member action: start, claim or referral bind.
  String? get actionError => _actionError;
  String? get referralError => _referralError;

  /// Parsed body of the most recent claim. A forfeit is reported here with
  /// `isExpired`, not through [actionError] — it is an outcome, not a crash.
  MiningClaimResult? get lastClaimResult => _lastClaimResult;

  /// Plain-English explanation of a cycle that expired unclaimed. Cleared by
  /// [clearForfeitNotice] once the UI has shown it.
  String? get forfeitNotice => _forfeitNotice;

  /// Server time minus device time, measured from the snapshot's `asOf`.
  Duration get clockOffset => _clockOffset;

  /// The device clock corrected by [clockOffset]. Countdowns use this so a
  /// phone whose clock is off does not promise the wrong ready time.
  DateTime serverNow() => _deviceClock().add(_clockOffset);

  bool get isBusy =>
      _isLoadingSnapshot ||
      _isLoadingReferral ||
      _isLoadingDownline ||
      _isLoadingLeaderboard ||
      _isStarting ||
      _isClaiming ||
      _isBindingReferral;

  void clearForfeitNotice() {
    if (_forfeitNotice == null) return;
    _forfeitNotice = null;
    notifyListeners();
  }

  Future<void> loadSnapshot({bool force = false}) async {
    if (_isLoadingSnapshot) return;
    if (!force && _snapshot != null) return;

    final generation = _generation;
    _isLoadingSnapshot = true;
    notifyListeners();

    if (_snapshot == null && _cachedBalance == null) {
      final cached = await _localCache.readBalance();
      if (generation == _generation) _cachedBalance = cached;
    }

    try {
      final snapshot = await _repository.fetchMiningSnapshot();
      if (generation != _generation) return;
      if (snapshot == null) {
        _snapshotError = 'Could not read your mining status.';
      } else {
        _applySnapshot(snapshot);
        _snapshotError = null;
      }
    } catch (error) {
      if (generation != _generation) return;
      _snapshotError = describeError(error);
    } finally {
      if (generation == _generation) {
        _isLoadingSnapshot = false;
        notifyListeners();
      }
    }
  }

  void _applySnapshot(MiningSnapshot snapshot) {
    _snapshot = snapshot;
    _cachedBalance = snapshot.balance.claimedTotalPoints;
    _localCache.writeBalance(snapshot.balance.claimedTotalPoints);
    if (snapshot.hasServerTime) {
      _clockOffset = snapshot.asOf.difference(_deviceClock());
    }
  }

  /// Refetches the snapshot once when the running cycle reaches its end by
  /// server time, so Claim appears without a manual pull. Returns whether a
  /// refetch was started. Guarded per session: if the server has not flipped
  /// the cycle yet, the hero asks for a pull instead of polling.
  bool refreshAtCycleEnd() {
    final session = _snapshot?.session;
    final endsAt = session?.endsAt;
    final sessionId = session?.id;
    if (session == null || !session.isRunning || endsAt == null) return false;
    if (sessionId == null || sessionId == _cycleEndRefetchedFor) return false;
    if (serverNow().isBefore(endsAt)) return false;

    _cycleEndRefetchedFor = sessionId;
    loadSnapshot(force: true);
    return true;
  }

  Future<void> loadReferralSummary({bool force = false}) async {
    if (_isLoadingReferral) return;
    if (!force && _referralSummary != null) return;

    final generation = _generation;
    _isLoadingReferral = true;
    notifyListeners();

    try {
      final summary = await _repository.fetchReferralSummary();
      if (generation != _generation) return;
      if (summary != null) _referralSummary = summary;
      _referralError = null;
    } catch (error) {
      if (generation != _generation) return;
      _referralError = describeError(error);
    } finally {
      if (generation == _generation) {
        _isLoadingReferral = false;
        notifyListeners();
      }
    }
  }

  /// Direct referrals. Fetched by the referral view only, never by
  /// [refreshAll]: nothing on the Mine tab shows it (F-54).
  Future<void> loadDownline({bool force = false}) async {
    if (_isLoadingDownline) return;
    if (!force && _downline.isNotEmpty) return;

    final generation = _generation;
    _isLoadingDownline = true;
    notifyListeners();

    try {
      final response = await _repository.fetchDownline(limit: 30, offset: 0);
      if (generation != _generation) return;
      _downline = response?.data ?? const [];
      _downlineError = null;
    } catch (error) {
      if (generation != _generation) return;
      _downlineError = describeError(error);
    } finally {
      if (generation == _generation) {
        _isLoadingDownline = false;
        notifyListeners();
      }
    }
  }

  /// Loads one page of the all-time board. Page one also refreshes the
  /// top three the Mine preview shows.
  Future<void> loadLeaderboard({bool force = false, int page = 1}) async {
    if (_isLoadingLeaderboard) return;
    final target = page < 1 ? 1 : page;
    if (!force && target == _leaderboardPage && _leaderboard.isNotEmpty) {
      return;
    }

    final generation = _generation;
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final response = await _repository.fetchLeaderboard(
        limit: leaderboardPageSize,
        offset: (target - 1) * leaderboardPageSize,
      );
      if (generation != _generation) return;
      _leaderboard = response?.data ?? const [];
      _leaderboardPage = target;
      _leaderboardTotal = response?.total ?? _leaderboard.length;
      _leaderboardMe = response?.me;
      if (target == 1) _leaderboardTop = _leaderboard.take(3).toList();
      _leaderboardError = null;
    } catch (error) {
      if (generation != _generation) return;
      _leaderboardError = describeError(error);
    } finally {
      if (generation == _generation) {
        _isLoadingLeaderboard = false;
        notifyListeners();
      }
    }
  }

  /// Everything the Mine tab shows. The downline is not part of it.
  Future<void> refreshAll() async {
    await Future.wait([
      loadSnapshot(force: true),
      loadReferralSummary(force: true),
      loadLeaderboard(force: true),
    ]);
  }

  String describeError(Object error) => MiningErrorCopy.describe(error);
}
