import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/device_token_registrar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

class _RecordedCall {
  _RecordedCall(this.path, {this.body, this.query});

  final String path;
  final Map<String, dynamic>? body;
  final Map<String, String>? query;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.deleteError}) : super(httpClient: _NoopHttpClient());

  final Object? deleteError;
  final List<_RecordedCall> posts = <_RecordedCall>[];
  final List<_RecordedCall> deletes = <_RecordedCall>[];

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    posts.add(_RecordedCall(path, body: body));
    return <String, dynamic>{'id': 'row-1'};
  }

  @override
  Future<dynamic> delete(String path, {Map<String, String>? query}) async {
    deletes.add(_RecordedCall(path, query: query));
    final error = deleteError;
    if (error != null) throw error;
    return <String, dynamic>{'deleted': true};
  }
}

DeviceTokenRegistrar _registrar(_FakeApiClient api) => DeviceTokenRegistrar(
      apiClient: api,
      platformResolver: () => 'android',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ApiClient.setAuthToken(null);
  });

  group('DeviceTokenRegistrar', () {
    test('register posts the token and retains it for later unregistration',
        () async {
      final api = _FakeApiClient();
      final registrar = _registrar(api);

      await registrar.register('fcm-token-a');

      expect(api.posts, hasLength(1));
      expect(api.posts.single.path, '/device-tokens/register');
      expect(api.posts.single.body, {
        'token': 'fcm-token-a',
        'platform': 'android',
      });
      expect(registrar.currentToken, 'fcm-token-a');
    });

    test('unregister sends the token value as a query parameter', () async {
      final api = _FakeApiClient();
      final registrar = _registrar(api);

      await registrar.register('fcm-token-a');
      await registrar.unregisterCurrentToken();

      expect(api.deletes, hasLength(1));
      expect(api.deletes.single.path, '/device-tokens');
      expect(api.deletes.single.query, {'token': 'fcm-token-a'});
      expect(registrar.currentToken, isNull);
    });

    test('unregister is a no-op when no token was ever registered', () async {
      final api = _FakeApiClient();

      await _registrar(api).unregisterCurrentToken();

      expect(api.deletes, isEmpty);
    });

    test('token refresh unregisters the old value before registering the new',
        () async {
      final api = _FakeApiClient();
      final registrar = _registrar(api);

      await registrar.register('fcm-token-old');
      await registrar.handleTokenRefresh('fcm-token-new');

      expect(api.deletes, hasLength(1));
      expect(api.deletes.single.query, {'token': 'fcm-token-old'});
      expect(api.posts.map((call) => call.body?['token']),
          ['fcm-token-old', 'fcm-token-new']);
      expect(registrar.currentToken, 'fcm-token-new');
    });

    test('token refresh with an unchanged value does not unregister it',
        () async {
      final api = _FakeApiClient();
      final registrar = _registrar(api);

      await registrar.register('fcm-token-a');
      await registrar.handleTokenRefresh('fcm-token-a');

      expect(api.deletes, isEmpty);
      expect(registrar.currentToken, 'fcm-token-a');
    });

    test('a failing delete does not throw', () async {
      final api = _FakeApiClient(deleteError: ApiException('offline'));
      final registrar = _registrar(api);

      await registrar.register('fcm-token-a');

      await expectLater(registrar.unregisterCurrentToken(), completes);
    });
  });

  group('AuthStore sign-out', () {
    test('unregisters the push token before clearing auth', () async {
      final api = _FakeApiClient();
      final registrar = _registrar(api);
      await registrar.register('fcm-token-a');

      String? tokenDuringUnregister;
      final store = AuthStore(
        apiClient: api,
        enableSupabaseAuthListener: false,
        supabaseConfiguredOverride: false,
      );
      addTearDown(store.dispose);

      ApiClient.setAuthToken('jwt-123');
      store.onBeforeSignOut = () {
        // Captured inside the hook: the bearer token must still be present,
        // otherwise the DELETE would go out unauthenticated.
        tokenDuringUnregister = ApiClient.debugAuthToken;
        return registrar.unregisterCurrentToken();
      };

      await store.signOut();

      expect(tokenDuringUnregister, 'jwt-123');
      expect(api.deletes, hasLength(1));
      expect(api.deletes.single.query, {'token': 'fcm-token-a'});
      expect(ApiClient.debugAuthToken, isNull);
      expect(store.isAuthenticated, isFalse);
    });

    test('still signs out locally when the unregister throws', () async {
      final api = _FakeApiClient();
      final store = AuthStore(
        apiClient: api,
        enableSupabaseAuthListener: false,
        supabaseConfiguredOverride: false,
      );
      addTearDown(store.dispose);

      ApiClient.setAuthToken('jwt-123');
      store.onBeforeSignOut = () async {
        throw ApiException('offline');
      };

      await expectLater(store.signOut(), completes);
      expect(ApiClient.debugAuthToken, isNull);
      expect(store.isAuthenticated, isFalse);
    });
  });
}
