import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth_store.dart';
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
  _FakeApiClient({
    required Future<dynamic> Function(String path, Map<String, dynamic>? body)
        postHandler,
    required Future<dynamic> Function(String path, Map<String, String>? query)
        getHandler,
  })  : _postHandler = postHandler,
        _getHandler = getHandler,
        super(httpClient: _NoopHttpClient());

  final Future<dynamic> Function(String path, Map<String, dynamic>? body)
      _postHandler;
  final Future<dynamic> Function(String path, Map<String, String>? query)
      _getHandler;

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _postHandler(path, body);
  }

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _getHandler(path, query);
  }
}

class _BootstrapTestAuthStore extends AuthStore {
  _BootstrapTestAuthStore({
    required super.apiClient,
    required String bootstrapToken,
    required String refreshedToken,
  })  : _bootstrapToken = bootstrapToken,
        _refreshedToken = refreshedToken,
        super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: true,
        );

  final String _bootstrapToken;
  final String _refreshedToken;
  int refreshAttempts = 0;

  @override
  Future<String?> getCurrentAccessTokenForBootstrap() async => _bootstrapToken;

  @override
  Future<String?> refreshAccessTokenSilently() async {
    refreshAttempts += 1;
    return _refreshedToken;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ApiClient.setAuthToken(null);
    ApiClient.setAuthTokenRefresher(null);
  });

  tearDown(() {
    ApiClient.setAuthToken(null);
    ApiClient.setAuthTokenRefresher(null);
  });

  test(
      'bootstrap retries once with refreshed access token when initial token is stale',
      () async {
    final fakeApiClient = _FakeApiClient(
      postHandler: (path, body) async {
        if (path != '/auth/session/verify') {
          throw StateError('Unexpected POST path: $path');
        }

        final token = body?['accessToken'] as String?;
        if (token == 'stale-access-token') {
          throw ApiException(
            'Request failed',
            statusCode: 401,
            responseBody: 'expired access token',
          );
        }

        return {
          'user': {
            'id': 'user-1',
            'email': 'user@example.com',
            'roles': ['user'],
          },
        };
      },
      getHandler: (path, query) async {
        if (path != '/me') {
          throw StateError('Unexpected GET path: $path');
        }

        return {
          'displayName': 'Tester',
          'avatarUrl': null,
          'bio': null,
          'username': 'tester',
          'walletStatus': null,
          'walletAddress': null,
          'kycStatus': null,
          'roles': ['user'],
          'createdAt': DateTime.now().toIso8601String(),
        };
      },
    );

    final store = _BootstrapTestAuthStore(
      apiClient: fakeApiClient,
      bootstrapToken: 'stale-access-token',
      refreshedToken: 'fresh-access-token',
    );

    await store.bootstrapFromSession();

    expect(store.refreshAttempts, 1);
    expect(store.isAuthenticated, isTrue);
    expect(store.accessToken, 'fresh-access-token');
  });
}
