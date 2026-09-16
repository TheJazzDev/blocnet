import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
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
}

void main() {
  late _FakeApiClient api;
  late HunterBoardStore store;

  setUp(() {
    api = _FakeApiClient();
    store = HunterBoardStore(
      repository: HunterReliabilityApiRepository(apiClient: api),
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

  test('clear drops all state', () async {
    await store.loadBoard();
    await store.loadLeaderboard();
    store.clear();
    expect(store.board, isNull);
    expect(store.leaderboard, isEmpty);
    expect(store.hasLoadedLeaderboard, isFalse);
    expect(store.reliabilityFor('me'), isNull);
  });
}
