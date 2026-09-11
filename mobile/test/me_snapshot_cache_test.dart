import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/users/me_snapshot_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

/// Counts every GET that actually reaches the transport.
class _CountingApiClient extends ApiClient {
  _CountingApiClient({this.responseBuilder})
      : super(httpClient: _NoopHttpClient());

  final Map<String, dynamic> Function(int callIndex)? responseBuilder;
  final List<String> getPaths = <String>[];

  int get meCalls => getPaths.where((path) => path == '/me').length;

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    getPaths.add(path);
    final build = responseBuilder;
    if (build != null) return build(getPaths.length);
    return <String, dynamic>{'id': 'user-1', 'followingCount': 3};
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async => null;

  @override
  Future<dynamic> delete(String path, {Map<String, String>? query}) async =>
      null;
}

void main() {
  setUp(MeSnapshotCache.reset);
  tearDown(MeSnapshotCache.reset);

  test('two fetchMe calls inside the TTL issue a single GET /me', () async {
    final apiClient = _CountingApiClient();
    final repository = UsersApiRepository(apiClient: apiClient);

    final first = await repository.fetchMe();
    final second = await repository.fetchMe();

    expect(apiClient.meCalls, 1);
    expect(first?['followingCount'], 3);
    expect(second, same(first));
  });

  test('concurrent misses share one in-flight GET /me', () async {
    final apiClient = _CountingApiClient();
    final repository = UsersApiRepository(apiClient: apiClient);

    final results = await Future.wait<Map<String, dynamic>?>([
      repository.fetchMe(),
      repository.fetchMe(),
      repository.fetchMe(),
    ]);

    expect(apiClient.meCalls, 1);
    expect(results[1], same(results[0]));
    expect(results[2], same(results[0]));
  });

  test('invalidate forces the next fetchMe to refetch', () async {
    final apiClient = _CountingApiClient(
      responseBuilder: (index) => <String, dynamic>{
        'id': 'user-1',
        'followingCount': index,
      },
    );
    final repository = UsersApiRepository(apiClient: apiClient);

    final first = await repository.fetchMe();
    expect(first?['followingCount'], 1);

    MeSnapshotCache.invalidate();

    final second = await repository.fetchMe();
    expect(apiClient.meCalls, 2);
    expect(second?['followingCount'], 2);
  });

  test('forceRefresh bypasses a fresh snapshot', () async {
    final apiClient = _CountingApiClient(
      responseBuilder: (index) => <String, dynamic>{
        'id': 'user-1',
        'followingCount': index,
      },
    );
    final repository = UsersApiRepository(apiClient: apiClient);

    await repository.fetchMe();
    final forced = await repository.fetchMe(forceRefresh: true);

    expect(apiClient.meCalls, 2);
    expect(forced?['followingCount'], 2);
    // The forced result becomes the new shared snapshot.
    expect(MeSnapshotCache.fresh?['followingCount'], 2);
  });

  test('a written snapshot satisfies fetchMe without any request', () async {
    final apiClient = _CountingApiClient();
    final repository = UsersApiRepository(apiClient: apiClient);

    // What `GET /me/home-bootstrap` does with its `meSummary`.
    MeSnapshotCache.write(<String, dynamic>{
      'id': 'user-1',
      'followedProjectIds': <String>['p1'],
    });

    final me = await repository.fetchMe();

    expect(apiClient.meCalls, 0);
    expect(me?['followedProjectIds'], <String>['p1']);
  });

  test('retainForUser drops a snapshot belonging to another account', () async {
    MeSnapshotCache.write(<String, dynamic>{'id': 'user-1'});

    MeSnapshotCache.retainForUser('user-1');
    expect(MeSnapshotCache.hasFresh, isTrue);

    MeSnapshotCache.retainForUser('user-2');
    expect(MeSnapshotCache.hasFresh, isFalse);
  });

  test('followProfile invalidates the snapshot', () async {
    final apiClient = _CountingApiClient();
    final repository = UsersApiRepository(apiClient: apiClient);

    await repository.fetchMe();
    expect(MeSnapshotCache.hasFresh, isTrue);

    await repository.followProfile('profile-1');

    expect(MeSnapshotCache.hasFresh, isFalse);
  });
}
