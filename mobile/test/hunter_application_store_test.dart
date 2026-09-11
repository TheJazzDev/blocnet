import 'package:blocnet/features/hunter/data/repositories/hunter_applications_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

Map<String, dynamic> _row(
  String id,
  String status,
  String createdAt, {
  String? reviewedAt,
}) =>
    {
      'id': id,
      'targetRole': 'hunter',
      'status': status,
      'reason': 'because',
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
    };

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(httpClient: _NoopHttpClient());

  Map<String, dynamic>? lastBody;
  String? lastPath;
  ApiException? failWith;

  /// Rows returned by `GET /admin-applications/mine`; null answers 404.
  List<Map<String, dynamic>>? mineRows = const [];
  int mineCalls = 0;
  Map<String, String>? lastMineQuery;

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    if (path == '/admin-applications/mine') {
      mineCalls += 1;
      lastMineQuery = query;
      final rows = mineRows;
      if (rows == null) {
        throw ApiException('Not Found', statusCode: 404);
      }
      return rows;
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    lastPath = path;
    lastBody = body;
    final error = failWith;
    if (error != null) throw error;
    return _row('app-new', 'pending', '2026-09-11T00:00:00Z')
      ..['reason'] = body?['reason'];
  }
}

HunterApplicationStore _store(_FakeApiClient api) => HunterApplicationStore(
      repository: HunterApplicationsApiRepository(apiClient: api),
    );

Future<bool?> _prefsFlag(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(HunterApplicationStore.pendingKeyFor(userId));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('scoping a user reads /mine with targetRole=hunter', () async {
    final api = _FakeApiClient()
      ..mineRows = [_row('a1', 'pending', '2026-09-01T00:00:00Z')];
    final store = _store(api);

    await store.ensureUserScope('u1', isHunter: false);

    expect(api.mineCalls, 1);
    expect(api.lastMineQuery, {'targetRole': 'hunter'});
    expect(store.status, HunterApplicationStatus.pending);
    expect(store.isPending, isTrue);
    expect(store.latest?.id, 'a1');
    expect(store.isUsingLocalFallback, isFalse);
    expect(await _prefsFlag('u1'), isTrue);
  });

  test('a rejected newest row shows rejected and clears the local flag',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HunterApplicationStore.pendingKeyFor('u1'): true,
    });
    final api = _FakeApiClient()
      ..mineRows = [
        _row('a2', 'rejected', '2026-09-05T00:00:00Z',
            reviewedAt: '2026-09-06T00:00:00Z'),
        _row('a1', 'approved', '2026-08-01T00:00:00Z'),
      ];
    final store = _store(api);

    await store.ensureUserScope('u1', isHunter: false);

    expect(store.isRejected, isTrue);
    expect(store.isPending, isFalse);
    expect(store.latest?.id, 'a2');
    expect(await _prefsFlag('u1'), isNull);
  });

  test('the newest row wins regardless of server ordering', () async {
    final api = _FakeApiClient()
      ..mineRows = [
        _row('old', 'rejected', '2026-01-01T00:00:00Z'),
        _row('new', 'approved', '2026-09-01T00:00:00Z'),
      ];
    final store = _store(api);

    await store.ensureUserScope('u1', isHunter: false);

    expect(store.isApproved, isTrue);
    expect(store.latest?.id, 'new');
  });

  test('approved collapses to none once the account holds the hunter role',
      () async {
    final api = _FakeApiClient()
      ..mineRows = [_row('a1', 'approved', '2026-09-01T00:00:00Z')];
    final store = _store(api);

    await store.ensureUserScope('u1', isHunter: false);
    expect(store.isApproved, isTrue);

    await store.ensureUserScope('u1', isHunter: true);
    expect(store.status, HunterApplicationStatus.none);
    expect(await _prefsFlag('u1'), isNull);
  });

  test('a 404 from /mine keeps the local pending flag as fallback', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HunterApplicationStore.pendingKeyFor('u1'): true,
    });
    final api = _FakeApiClient()..mineRows = null;
    final store = _store(api);

    await store.ensureUserScope('u1', isHunter: false);

    expect(api.mineCalls, 1);
    expect(store.isPending, isTrue);
    expect(store.isUsingLocalFallback, isTrue);
    expect(store.lastError, isNull);
  });

  test('no rows and no flag means no application', () async {
    final store = _store(_FakeApiClient());

    await store.ensureUserScope('u1', isHunter: false);

    expect(store.status, HunterApplicationStatus.none);
    expect(store.latest, isNull);
  });

  test('submit posts targetRole=hunter and marks the application pending',
      () async {
    final api = _FakeApiClient();
    final store = _store(api);
    await store.ensureUserScope('u1', isHunter: false);

    final ok = await store.submit('  I research L2s every day.  ');

    expect(ok, isTrue);
    expect(api.lastPath, '/admin-applications');
    expect(api.lastBody, {
      'targetRole': 'hunter',
      'reason': 'I research L2s every day.',
    });
    expect(store.isPending, isTrue);
    expect(await _prefsFlag('u1'), isTrue);
  });

  test('re-applying after a rejection moves back to pending', () async {
    final api = _FakeApiClient()
      ..mineRows = [_row('a1', 'rejected', '2026-09-01T00:00:00Z')];
    final store = _store(api);
    await store.ensureUserScope('u1', isHunter: false);
    expect(store.isRejected, isTrue);

    final ok = await store.submit('Second attempt with more detail.');

    expect(ok, isTrue);
    expect(store.isPending, isTrue);
    expect(store.latest?.id, 'app-new');
  });

  test('an "already pending" 400 still lands in the pending state', () async {
    final api = _FakeApiClient()
      ..failWith = ApiException(
        'Request failed',
        statusCode: 400,
        responseBody: '{"message":"You already have a pending application"}',
      );
    final store = _store(api);
    await store.ensureUserScope('u1', isHunter: false);

    final ok = await store.submit('Long enough reason text here.');

    expect(ok, isTrue);
    expect(store.isPending, isTrue);
    expect(store.lastError, isNull);
  });

  test('other failures surface the message and stay not pending', () async {
    final api = _FakeApiClient()
      ..failWith = ApiException('Request failed', statusCode: 500);
    final store = _store(api);
    await store.ensureUserScope('u1', isHunter: false);

    final ok = await store.submit('Long enough reason text here.');

    expect(ok, isFalse);
    expect(store.isPending, isFalse);
    expect(store.lastError, 'Request failed (500)');
  });

  test('switching users re-scopes and a hunter drops a stale pending flag',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HunterApplicationStore.pendingKeyFor('u1'): true,
    });
    final api = _FakeApiClient()..mineRows = null;
    final store = _store(api);

    await store.ensureUserScope('u1', isHunter: false);
    expect(store.isPending, isTrue);

    await store.ensureUserScope('u2', isHunter: false);
    expect(store.isPending, isFalse);

    await store.ensureUserScope('u1', isHunter: true);
    expect(store.isPending, isFalse);
    expect(await _prefsFlag('u1'), isNull);
  });

  test('submit is refused without a user scope or an empty reason', () async {
    final api = _FakeApiClient();
    final store = _store(api);

    expect(await store.submit('reason'), isFalse);
    await store.ensureUserScope('u1', isHunter: false);
    expect(await store.submit('   '), isFalse);
    expect(api.lastPath, isNull);
  });
}
