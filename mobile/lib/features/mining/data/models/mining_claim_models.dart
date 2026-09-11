import 'package:blocnet/features/mining/data/models/mining_models.dart';

/// Outcome of `POST /mining/claim`.
///
/// The endpoint answers 200 in two very different cases and the difference is
/// only in the body:
///
///  * `status: 'claimed'` — points were paid out.
///  * `status: 'expired'` — every candidate cycle had already passed its claim
///    window, so it was forfeited instead. `ok` is false, `claimedPoints` is 0
///    and nothing reached the balance.
///
/// Treating "no exception" as success silently swallows the second case, so
/// callers must branch on [isClaimed] / [isExpired].
class MiningClaimResult {
  const MiningClaimResult({
    required this.ok,
    required this.status,
    required this.code,
    required this.message,
    required this.sessionId,
    required this.claimedAt,
    required this.claimedPoints,
    required this.forfeitedPoints,
    required this.expiredCycles,
    required this.balance,
    required this.nextSession,
  });

  final bool ok;

  /// `claimed` or `expired`.
  final String status;

  /// Machine code on the expired branch, e.g. `claim_window_expired`.
  final String? code;

  /// Server-side explanation. Kept for diagnostics; the user-facing copy is
  /// built client-side from the numbers so it can name the actual amount.
  final String? message;

  final String? sessionId;
  final DateTime? claimedAt;
  final int claimedPoints;
  final int forfeitedPoints;
  final List<MiningExpiredCycle> expiredCycles;

  /// Authoritative balance after settlement. Can be *lower* than a cached one,
  /// because forfeited checkpoints no longer count towards
  /// `maturedUnclaimedPoints` or `lifetimeEarnedPoints`.
  final MiningBalanceModel? balance;

  /// The cycle the backend auto-opened. Null when mining is disabled or a
  /// claimable cycle is still outstanding.
  final MiningSessionModel? nextSession;

  bool get isClaimed => status == 'claimed' && ok;
  bool get isExpired => status == 'expired' || !ok;
  bool get startedNextCycle => nextSession != null;

  factory MiningClaimResult.fromApi(Map<String, dynamic> json) {
    final balanceRaw = (json['balance'] as Map?)?.cast<String, dynamic>();
    final nextSessionRaw =
        (json['nextSession'] as Map?)?.cast<String, dynamic>();

    return MiningClaimResult(
      ok: json['ok'] != false,
      status: json['status']?.toString() ?? 'claimed',
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      sessionId: json['sessionId']?.toString(),
      claimedAt: DateTime.tryParse(json['claimedAt']?.toString() ?? ''),
      claimedPoints:
          int.tryParse(json['claimedPoints']?.toString() ?? '') ?? 0,
      forfeitedPoints:
          int.tryParse(json['forfeitedPoints']?.toString() ?? '') ?? 0,
      expiredCycles: MiningExpiredCycle.listFromApi(json['expiredCycles']),
      balance: balanceRaw == null
          ? null
          : MiningBalanceModel.fromApi(balanceRaw),
      nextSession: nextSessionRaw == null
          ? null
          : MiningSessionModel.fromApi(nextSessionRaw),
    );
  }

  /// Fallback for a body the client could not parse. Deliberately *not* a
  /// success: an unreadable response must never be reported as a payout.
  factory MiningClaimResult.unknown() {
    return const MiningClaimResult(
      ok: false,
      status: 'unknown',
      code: null,
      message: null,
      sessionId: null,
      claimedAt: null,
      claimedPoints: 0,
      forfeitedPoints: 0,
      expiredCycles: <MiningExpiredCycle>[],
      balance: null,
      nextSession: null,
    );
  }
}

/// Outcome of `POST /mining/start`. Carries `expiredCycles[]` because start
/// also reconciles: opening a new cycle can forfeit older ones on the way.
class MiningStartResult {
  const MiningStartResult({
    required this.ok,
    required this.status,
    required this.expiredCycles,
    required this.session,
  });

  final bool ok;

  /// `started` for a fresh cycle, `running` when one was already live.
  final String status;
  final List<MiningExpiredCycle> expiredCycles;
  final MiningSessionModel? session;

  int get forfeitedPoints => expiredCycles.fold<int>(
        0,
        (total, cycle) => total + cycle.forfeitedPoints,
      );

  bool get hasExpiredCycles => expiredCycles.isNotEmpty;

  factory MiningStartResult.fromApi(Map<String, dynamic> json) {
    final sessionRaw = (json['session'] as Map?)?.cast<String, dynamic>();
    return MiningStartResult(
      ok: json['ok'] != false,
      status: json['status']?.toString() ?? 'started',
      expiredCycles: MiningExpiredCycle.listFromApi(json['expiredCycles']),
      session:
          sessionRaw == null ? null : MiningSessionModel.fromApi(sessionRaw),
    );
  }

  factory MiningStartResult.unknown() {
    return const MiningStartResult(
      ok: true,
      status: 'started',
      expiredCycles: <MiningExpiredCycle>[],
      session: null,
    );
  }
}
