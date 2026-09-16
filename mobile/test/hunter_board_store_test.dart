import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

Map<String, dynamic> _reliability(String id, {String standing = 'reliable'}) =>
    {
      'profileId': id,
      'standing': standing,
      'coverage': 1,
      'gemsOwned': 1,
      'tipsReceivedTotal': '0',
    };

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(httpClient: _NoopHttpClient());

  final List<String> paths = [];
  final List<Map<String, String>?> queries = [];
  final Map<String, Object> failures = {};
  final List<Map<String, dynamic>?> bodies = [];

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    paths.add(path);
    queries.add(query);
    final failure = failures[path];
    if (failure != null) throw failure;

    if (path == '/me/hunter/board') {
      return {
        'reliability': _reliability('me'),
        'gems': [
          {'projectId': 'g1', 'name': 'Gem', 'state': 'due', 'daysQuiet': 11},
        ],
      };
    }
    if (path.startsWith('/me/hunter/gems/')) {
      return {
        'gem': {'projectId': path.split('/').last, 'name': 'Gem'},
        'updates': [
          {'id': 'u1', 'title': 'Hello', 'createdAt': '2026-09-01T00:00:00Z'},
        ],
        'gapDays': 12,
      };
    }
    if (path == '/project-proposals/mine') {
      return [
        {
          'id': 'pp1',
          'name': 'Lumen Pay',
          'status': 'pending',
          'createdAt': '2026-09-14T00:00:00Z',
        },
      ];
    }
    if (path.startsWith('/hunters/') && path.endsWith('/reliability')) {
      final id = path.split('/')[2];
      return _reliability(id, standing: 'quiet');
    }
    if (path == '/hunters/leaderboard') {
      final cursor = query?['cursor'];
      return cursor == null
          ? {
              'items': [
                {..._reliability('a'), 'rank': 1},
                {..._reliability('b'), 'rank': 2},
              ],
              'nextCursor': '2',
            }
          : {
              'items': [
                {..._reliability('c'), 'rank': 3},
              ],
              'nextCursor': null,
            };
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    paths.add('POST $path');
    bodies.add(body);
    final failure = failures['POST $path'];
    if (failure != null) throw failure;
    return {'id': 'inv-1', 'kind': 'handover', 'status': 'pending'};
  }

  @override
  Future<dynamic> delete(String path, {Map<String, String>? query}) async {
    paths.add('DELETE $path');
    final failure = failures['DELETE $path'];
    if (failure != null) throw failure;
    return {'id': 'inv-1', 'status': 'cancelled'};
  }
}

void main() {
  late _FakeApiClient api;
  late HunterBoardStore store;

  setUp(() {
    api = _FakeApiClient();
    store = HunterBoardStore(
      repository: HunterReliabilityApiRepository(apiClient: api),
      proposalsRepository: ProjectProposalsApiRepository(apiClient: api),
    );
  });

  test('loadBoard fills the board and caches the hunter’s own reliability',
      () async {
    await store.loadBoard();

    expect(store.boardError, isNull);
    expect(store.isLoadingBoard, isFalse);
    expect(store.board?.gems.single.projectId, 'g1');
    expect(store.reliabilityFor('me')?.gemsOwned, 1);
  });

  test('a failed board refresh keeps the last good board', () async {
    await store.loadBoard();
    api.failures['/me/hunter/board'] =
        ApiException('Forbidden', statusCode: 403);

    await store.loadBoard();

    expect(store.board, isNotNull);
    expect(store.boardError, isNotNull);
  });

  test('loadReliability caches per profile and records errors per profile',
      () async {
    await store.loadReliability('h1');
    expect(api.paths.last, '/hunters/h1/reliability');
    expect(store.reliabilityFor('h1')?.profileId, 'h1');
    expect(store.reliabilityErrorFor('h1'), isNull);

    api.failures['/hunters/h2/reliability'] =
        ApiException('Not Found', statusCode: 404);
    await store.loadReliability('h2');
    expect(store.reliabilityFor('h2'), isNull);
    expect(store.reliabilityErrorFor('h2'), isNotNull);
    expect(store.isLoadingReliability('h2'), isFalse);
  });

  test('loadLeaderboard pages with the cursor and stops at the end', () async {
    await store.loadLeaderboard();
    expect(store.leaderboard.map((e) => e.rank), [1, 2]);
    expect(store.hasMoreLeaderboard, isTrue);
    expect(api.queries.last, {'limit': '20'});

    await store.loadLeaderboard(loadMore: true);
    expect(
        store.leaderboard.map((e) => e.reliability.profileId), ['a', 'b', 'c']);
    expect(api.queries.last, {'limit': '20', 'cursor': '2'});
    expect(store.hasMoreLeaderboard, isFalse);

    final calls = api.paths.length;
    await store.loadLeaderboard(loadMore: true);
    expect(api.paths.length, calls, reason: 'no request past the last page');

    // A fresh load replaces rather than appends.
    await store.loadLeaderboard();
    expect(store.leaderboard.length, 2);
  });

  test('loadGem caches one gem and keeps it through a failed refresh',
      () async {
    await store.loadGem('g1');
    expect(api.paths.last, '/me/hunter/gems/g1');
    expect(store.gemFor('g1')?.updates.single.id, 'u1');
    expect(store.gemFor('g1')?.gapDays, 12);
    expect(store.isLoadingGem('g1'), isFalse);

    api.failures['/me/hunter/gems/g1'] =
        ApiException('Not Found', statusCode: 404);
    await store.loadGem('g1');
    expect(store.gemFor('g1'), isNotNull);
    expect(store.gemErrorFor('g1'), isNotNull);
  });

  test('loadPendingProposals asks for pending submissions only', () async {
    await store.loadPendingProposals();
    expect(api.paths.last, '/project-proposals/mine');
    expect(api.queries.last?['status'], 'pending');
    expect(store.pendingProposals.single.name, 'Lumen Pay');
    expect(store.hasLoadedProposals, isTrue);
  });

  test('startHandover posts the hunter and a trimmed note', () async {
    final id =
        await store.startHandover('g1', ' kemi ', note: '  over to you ');

    expect(id, 'inv-1');
    expect(api.paths.last, 'POST /projects/g1/handover');
    expect(api.bodies.last, {'hunter': 'kemi', 'note': 'over to you'});
    expect(store.isHandoverBusy('g1'), isFalse);
    expect(store.handoverErrorFor('g1'), isNull);

    await store.startHandover('g1', 'kemi', note: '   ');
    expect(api.bodies.last, {'hunter': 'kemi'});
  });

  test('a failed handover records the server’s reason for that gem', () async {
    api.failures['POST /projects/g1/handover'] = ApiException(
      'Request failed',
      statusCode: 409,
      responseBody:
          '{"message":"This gem already has a handover waiting for an answer"}',
    );

    final id = await store.startHandover('g1', 'kemi');

    expect(id, isNull);
    expect(store.handoverErrorFor('g1'), contains('already has a handover'));
    expect(store.handoverErrorFor('g2'), isNull);
    expect(store.isHandoverBusy('g1'), isFalse);
  });

  test('cancelHandover deletes and clears an earlier error', () async {
    api.failures['DELETE /projects/g1/handover'] =
        ApiException('Not Found', statusCode: 404);
    expect(await store.cancelHandover('g1'), isFalse);
    expect(store.handoverErrorFor('g1'), isNotNull);

    api.failures.remove('DELETE /projects/g1/handover');
    expect(await store.cancelHandover('g1'), isTrue);
    expect(api.paths.last, 'DELETE /projects/g1/handover');
    expect(store.handoverErrorFor('g1'), isNull);
  });

  test('clear drops all state', () async {
    await store.loadBoard();
    await store.loadGem('g1');
    await store.loadPendingProposals();
    await store.loadLeaderboard();
    store.clear();
    expect(store.board, isNull);
    expect(store.leaderboard, isEmpty);
    expect(store.hasLoadedLeaderboard, isFalse);
    expect(store.reliabilityFor('me'), isNull);
    expect(store.gemFor('g1'), isNull);
    expect(store.pendingProposals, isEmpty);
  });
}
