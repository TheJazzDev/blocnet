import 'dart:async';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _levelJson(int level, {String name = 'Level'}) => {
      'id': 'lvl-$level',
      'slug': 'level-$level',
      'name': '$name $level',
      'description': '',
      'iconUrl': '',
      'level': level,
      'requiredBnp': '${level * 1000}',
      'requiredComments': level,
      'requiredDaysActive': level,
      'requiredQuests': 0,
      'requiredUpdates': 0,
      'requiredProjects': 0,
      'color': '#8A96A8',
      'isActive': true,
      'sortOrder': level,
    };

Map<String, dynamic> _progressJson({required int level, String bnp = '5000'}) =>
    {
      'currentLevel': _levelJson(level),
      'nextLevel': _levelJson(level + 1),
      'achievedAt': '2026-01-01T00:00:00Z',
      'metrics': {
        'totalBnpEarned': bnp,
        'totalComments': 4,
        'totalDaysActive': 9,
        'totalQuestsCompleted': 1,
        'totalUpdates': 0,
        'totalProjects': 0,
      },
      'progressToNext': {
        'bnp': {'current': bnp, 'required': '6000', 'percentage': 83},
        'comments': {'current': '4', 'required': '6', 'percentage': 66},
        'daysActive': {'current': '9', 'required': '6', 'percentage': 100},
        'quests': {'current': '1', 'required': '0', 'percentage': 100},
        'updates': {'current': '0', 'required': '0', 'percentage': 100},
        'projects': {'current': '0', 'required': '0', 'percentage': 100},
      },
    };

class _FakeApiClient extends ApiClient {
  _FakeApiClient();

  final List<String> calls = [];
  Map<String, dynamic>? recalculateResponse;
  Object? recalculateError;
  Object? progressError;
  int progressLevel = 3;
  Completer<void>? progressGate;

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    calls.add('GET $path');
    if (path == '/levels/me') {
      final gate = progressGate;
      if (gate != null) await gate.future;
      final error = progressError;
      if (error != null) throw error;
      return _progressJson(level: progressLevel);
    }
    if (path == '/levels') {
      return [for (var n = 1; n <= 15; n++) _levelJson(n)];
    }
    throw ApiException('unexpected GET $path', statusCode: 404);
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    calls.add('PATCH $path');
    if (path == '/levels/me/recalculate') {
      final error = recalculateError;
      if (error != null) throw error;
      return recalculateResponse;
    }
    throw ApiException('unexpected PATCH $path', statusCode: 404);
  }
}

void main() {
  group('LevelsStore.recalculateMyLevel', () {
    test('parses levelChanged and refreshes full progress from /levels/me',
        () async {
      final api = _FakeApiClient()..progressLevel = 3;
      final store = LevelsStore(apiClient: api);
      await store.fetchMyProgress();
      expect(store.myProgress?.currentLevel.level, 3);

      api
        ..progressLevel = 4
        ..recalculateResponse = {
          'levelChanged': true,
          'previousLevel': _levelJson(3),
          'currentLevel': _levelJson(4),
        };

      var notifications = 0;
      store.addListener(() => notifications++);

      final ok = await store.recalculateMyLevel();

      expect(ok, isTrue);
      expect(store.levelChanged, isTrue);
      expect(store.isRecalculating, isFalse);
      expect(api.calls, [
        'GET /levels/me',
        'PATCH /levels/me/recalculate',
        'GET /levels/me',
      ]);

      final progress = store.myProgress!;
      expect(progress.currentLevel.level, 4);
      // Metrics and next level survive because we re-fetched instead of
      // parsing the partial recalculate payload.
      expect(progress.nextLevel?.level, 5);
      expect(progress.metrics.totalComments, 4);
      expect(progress.progressToNext?.bnp.percentage, 83);
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('reports levelChanged=false when the level did not move', () async {
      final api = _FakeApiClient()
        ..progressLevel = 3
        ..recalculateResponse = {
          'levelChanged': false,
          'previousLevel': null,
          'currentLevel': _levelJson(3),
        };
      final store = LevelsStore(apiClient: api);

      final ok = await store.recalculateMyLevel();

      expect(ok, isTrue);
      expect(store.levelChanged, isFalse);
      expect(store.myProgress?.currentLevel.level, 3);
      expect(store.myProgress?.metrics.totalDaysActive, 9);
    });

    test('keeps existing metrics and applies the confirmed level when the '
        'refresh fails', () async {
      final api = _FakeApiClient()..progressLevel = 3;
      final store = LevelsStore(apiClient: api);
      await store.fetchMyProgress();

      api
        ..progressError = ApiException('offline', statusCode: 503)
        ..recalculateResponse = {
          'levelChanged': true,
          'previousLevel': _levelJson(3),
          'currentLevel': _levelJson(4, name: 'Fresh'),
        };

      final ok = await store.recalculateMyLevel();

      expect(ok, isTrue);
      expect(store.levelChanged, isTrue);
      expect(store.progressError, 'offline');
      expect(store.myProgress?.currentLevel.level, 4);
      expect(store.myProgress?.currentLevel.name, 'Fresh 4');
      expect(store.myProgress?.metrics.totalComments, 4);
      expect(store.myProgress?.nextLevel?.level, 4);
    });

    test('returns false and resets the flag when the request fails', () async {
      final api = _FakeApiClient()
        ..recalculateError = ApiException('boom', statusCode: 500);
      final store = LevelsStore(apiClient: api);

      final ok = await store.recalculateMyLevel();

      expect(ok, isFalse);
      expect(store.levelChanged, isFalse);
      expect(store.isRecalculating, isFalse);
      expect(store.myProgress, isNull);
      expect(api.calls, ['PATCH /levels/me/recalculate']);
    });

    test('waits for an in-flight progress fetch before refreshing', () async {
      final api = _FakeApiClient()
        ..progressLevel = 3
        ..progressGate = Completer<void>()
        ..recalculateResponse = {
          'levelChanged': true,
          'previousLevel': _levelJson(3),
          'currentLevel': _levelJson(4),
        };
      final store = LevelsStore(apiClient: api);

      final firstFetch = store.fetchMyProgress();
      final recalc = store.recalculateMyLevel();
      await Future<void>.delayed(Duration.zero);

      // Only the stale fetch and the PATCH have gone out so far.
      expect(api.calls, ['GET /levels/me', 'PATCH /levels/me/recalculate']);

      api.progressLevel = 4;
      api.progressGate!.complete();
      api.progressGate = null;
      await firstFetch;
      await recalc;

      expect(api.calls.last, 'GET /levels/me');
      expect(api.calls.where((c) => c == 'GET /levels/me').length, 2);
      expect(store.myProgress?.currentLevel.level, 4);
    });

    test('concurrent fetchMyProgress calls share one request', () async {
      final api = _FakeApiClient();
      final store = LevelsStore(apiClient: api);

      await Future.wait([store.fetchMyProgress(), store.fetchMyProgress()]);

      expect(api.calls, ['GET /levels/me']);
    });
  });
}
