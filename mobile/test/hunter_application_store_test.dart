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

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(httpClient: _NoopHttpClient());

  Map<String, dynamic>? lastBody;
  String? lastPath;
  ApiException? failWith;

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    lastPath = path;
    lastBody = body;
    final error = failWith;
    if (error != null) throw error;
    return {
      'id': 'app-1',
      'userId': 'u1',
      'targetRole': 'hunter',
      'reason': body?['reason'],
      'status': 'pending',
      'createdAt': '2026-09-11T00:00:00Z',
    };
  }
}

HunterApplicationStore _store(_FakeApiClient api) => HunterApplicationStore(
      repository: HunterApplicationsApiRepository(apiClient: api),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(HunterApplicationStore.pendingKeyFor('u1')), isTrue);
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

  test('pending flag is restored per user and cleared once hunter', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HunterApplicationStore.pendingKeyFor('u1'): true,
    });
    final store = _store(_FakeApiClient());

    await store.ensureUserScope('u1', isHunter: false);
    expect(store.isPending, isTrue);

    await store.ensureUserScope('u2', isHunter: false);
    expect(store.isPending, isFalse);

    await store.ensureUserScope('u1', isHunter: true);
    expect(store.isPending, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(HunterApplicationStore.pendingKeyFor('u1')), isNull);
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
