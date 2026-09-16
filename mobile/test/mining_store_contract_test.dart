import 'dart:async';
import 'dart:convert';

import 'package:blocnet/features/mining/data/mining_error_copy.dart';
import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mining_fixtures.dart';

class _Repo extends MiningApiRepository {
  _Repo({Map<String, dynamic>? snapshot}) : snapshotBody = snapshot;

  Map<String, dynamic>? snapshotBody;
  Object? snapshotError;
  Object? leaderboardError;
  Completer<void>? snapshotGate;
  Map<String, dynamic>? startBody;
  Object? startError;
  int snapshotCalls = 0;
  int downlineCalls = 0;

  @override
  Future<MiningSnapshot?> fetchMiningSnapshot() async {
    snapshotCalls++;
    await snapshotGate?.future;
    if (snapshotError != null) throw snapshotError!;
    final body = snapshotBody;
    return body == null ? null : MiningSnapshot.fromApi(body);
  }

  @override
  Future<MiningStartResult> startMining() async {
    if (startError != null) throw startError!;
    final body = startBody;
    return body == null
        ? MiningStartResult.unknown()
        : MiningStartResult.fromApi(body);
  }

  @override
  Future<ReferralSummaryModel?> fetchReferralSummary() async => null;

  @override
  Future<DownlineResponse?> fetchDownline({
    int limit = 20,
    int offset = 0,
  }) async {
    downlineCalls++;
    return null;
  }

  @override
  Future<MiningLeaderboardResponse?> fetchLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async {
    if (leaderboardError != null) throw leaderboardError!;
    return null;
  }
}

ApiException _conflict(String code, String message) => ApiException(
      'Request failed (409)',
      statusCode: 409,
      responseBody: jsonEncode({'code': code, 'message': message}),
    );

void main() {
  group('MiningStore requests (F-54)', () {
    test('refreshAll does not fetch the downline', () async {
      final repo = _Repo(snapshot: miningSnapshotJson());
      final store = MiningStore(repository: repo);

      await store.refreshAll();

      expect(repo.downlineCalls, 0);
      await store.loadDownline(force: true);
      expect(repo.downlineCalls, 1);
    });

    test('a failed leaderboard does not read as a snapshot failure', () async {
      final repo = _Repo(snapshot: miningSnapshotJson())
        ..leaderboardError = ApiException('boom', statusCode: 500);
      final store = MiningStore(repository: repo);

      await store.refreshAll();

      expect(store.leaderboardError, 'boom');
      expect(store.snapshotError, isNull);
      expect(store.actionError, isNull);
      expect(store.snapshot, isNotNull);
    });

    test('an unreadable snapshot is an error, not an endless load', () async {
      final store = MiningStore(repository: _Repo());

      await store.loadSnapshot();

      expect(store.snapshot, isNull);
      expect(store.isLoadingSnapshot, isFalse);
      expect(store.snapshotError, isNotNull);
    });

    test('clear drops cached data and a response that lands after it',
        () async {
      final repo = _Repo(snapshot: miningSnapshotJson());
      final store = MiningStore(repository: repo);
      await store.loadSnapshot();
      expect(store.snapshot, isNotNull);

      repo.snapshotGate = Completer<void>();
      final inFlight = store.loadSnapshot(force: true);
      store.clear();
      expect(store.snapshot, isNull);
      expect(store.isLoadingSnapshot, isFalse);

      repo.snapshotGate!.complete();
      await inFlight;
      expect(store.snapshot, isNull, reason: 'belongs to the old account');
    });
  });

  group('MiningErrorCopy', () {
    test('prefers the conflict code over the developer message', () {
      expect(
        MiningErrorCopy.describe(_conflict(
          'claim_required',
          'Claim the previous mining cycle before starting a new one',
        )),
        MiningErrorCopy.claimRequired,
      );
      expect(
        MiningErrorCopy.describe(_conflict('not_claimable', 'x')),
        MiningErrorCopy.notClaimable,
      );
    });

    test('a disabled-mining 400 reads as paused', () {
      final error = ApiException(
        'Request failed (400)',
        statusCode: 400,
        responseBody: jsonEncode({'message': 'Mining is disabled'}),
      );
      expect(MiningErrorCopy.describe(error), MiningErrorCopy.miningPaused);
    });

    test('startMining surfaces the friendly copy as an action error',
        () async {
      final repo = _Repo(snapshot: miningSnapshotJson())
        ..startError = _conflict('claim_required', 'dev text');
      final store = MiningStore(repository: repo);

      await expectLater(store.startMining(), throwsA(isA<ApiException>()));
      expect(store.actionError, MiningErrorCopy.claimRequired);
    });
  });

  group('response contract', () {
    test('an unreadable start is not a success', () async {
      final store = MiningStore(repository: _Repo(snapshot: miningSnapshotJson()));

      final result = await store.startMining();

      expect(result?.isStarted, isFalse);
      expect(MiningStartResult.fromApi(const {}).isStarted, isFalse);
      expect(
        MiningStartResult.fromApi(const {'ok': true, 'status': 'started'})
            .isStarted,
        isTrue,
      );
    });

    test('a claim body without status is neither claimed nor expired', () {
      final result = MiningClaimResult.fromApi(const {'claimedPoints': 120});

      expect(result.status, 'unknown');
      expect(result.isClaimed, isFalse);
      expect(result.isExpired, isFalse);
    });

    test('a running session without cycleHours does not invent 24', () {
      final snapshot = MiningSnapshot.fromApi(
        miningSnapshotJson(session: runningSessionJson(), cycleHours: 12),
      );

      expect(snapshot.session.cycleHours, isNull);
      expect(snapshot.config.cycleHours, 12);
    });
  });

  group('server clock (F-55)', () {
    test('offsets the device clock by asOf', () async {
      final device = DateTime.utc(2026, 9, 16, 11, 55);
      final store = MiningStore(
        repository: _Repo(snapshot: miningSnapshotJson()),
        deviceClock: () => device,
      );

      await store.loadSnapshot();

      expect(store.clockOffset, const Duration(minutes: 5));
      expect(store.serverNow(), miningAsOf);
    });

    test('refetches exactly once when the cycle reaches its end', () async {
      var device = miningAsOf;
      final repo = _Repo(
        snapshot: miningSnapshotJson(
          session: runningSessionJson(
            endsAt: miningAsOf.add(const Duration(seconds: 10)),
          ),
        ),
      );
      final store = MiningStore(repository: repo, deviceClock: () => device);
      await store.loadSnapshot();
      expect(repo.snapshotCalls, 1);

      expect(store.refreshAtCycleEnd(), isFalse, reason: 'not ended yet');

      device = miningAsOf.add(const Duration(seconds: 11));
      expect(store.refreshAtCycleEnd(), isTrue);
      await pumpEventQueue();
      expect(repo.snapshotCalls, 2);

      // The server still says running: no polling loop.
      expect(store.refreshAtCycleEnd(), isFalse);
      await pumpEventQueue();
      expect(repo.snapshotCalls, 2);
    });
  });
}
