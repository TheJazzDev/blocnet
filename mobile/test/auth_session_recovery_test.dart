import 'dart:async';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/auth/session_identity_cache.dart';
import 'package:blocnet/services/auth/session_refresh_policy.dart';
import 'package:blocnet/services/users/me_snapshot_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

typedef _Handler = Future<dynamic> Function(String path, Object? payload);

class _ScriptedApiClient extends ApiClient {
  _ScriptedApiClient(this.handler) : super(httpClient: _NoopHttpClient());

  _Handler handler;
  final List<String> calls = <String>[];

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    calls.add('POST $path');
    return handler(path, body);
  }

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) {
    calls.add('GET $path');
    return handler(path, query);
  }
}

ApiException _offline() =>
    ApiException('Unable to connect right now.', isNetworkError: true);

ApiException _unauthorized() => ApiException(
      'Invalid or expired token',
      statusCode: 401,
      responseBody: '{"message":"Invalid or expired token"}',
    );

Map<String, dynamic> _verified(List<String> roles) => {
      'user': {'id': 'user-1', 'email': 'hunter@example.com', 'roles': roles},
    };

Map<String, dynamic> _me(List<String> roles) => {
      'id': 'user-1',
      'displayName': 'Hunter',
      'username': 'hunter',
      'roles': roles,
    };

/// Supabase is replaced by two overridable seams: the persisted access token
/// and the refresh call. Everything else runs the real store.
class _TestAuthStore extends AuthStore {
  _TestAuthStore({
    required super.apiClient,
    super.connectivityRestored,
    super.refreshBackoff,
  }) : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: true,
        );

  final String bootstrapToken = 'stale-token';
  Future<String> Function() refresh = () async => 'fresh-token';
  int refreshRequests = 0;

  @override
  Future<String?> getCurrentAccessTokenForBootstrap() async => bootstrapToken;

  @override
  Future<String> requestRefreshedAccessToken() {
    refreshRequests += 1;
    return refresh();
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ApiClient.setAuthToken(null);
    ApiClient.setAuthTokenRefresher(null);
    ApiClient.setSessionRejectedHandler(null);
    MeSnapshotCache.reset();
  });

  tearDown(() {
    ApiClient.setAuthToken(null);
    ApiClient.setAuthTokenRefresher(null);
    ApiClient.setSessionRejectedHandler(null);
    MeSnapshotCache.reset();
  });

  group('dead session', () {
    test('a rejected refresh token signs out once and leaves a notice',
        () async {
      final api = _ScriptedApiClient((path, _) async => throw _unauthorized());
      final store = _TestAuthStore(apiClient: api)
        ..refresh = () async => throw AuthApiException(
              'Invalid Refresh Token: Refresh Token Not Found',
              statusCode: '400',
              code: 'refresh_token_not_found',
            );
      var beforeSignOutCalls = 0;
      store.onBeforeSignOut = () async => beforeSignOutCalls += 1;
      await SessionIdentityCache.save(
        const SessionIdentity(userId: 'user-1', roles: ['user', 'hunter']),
      );

      await store.bootstrapFromSession();

      expect(store.isAuthenticated, isFalse);
      expect(store.isBootstrapping, isFalse);
      expect(store.sessionEndedNotice, AuthStore.sessionEndedMessage);
      expect(beforeSignOutCalls, 1);
      expect(ApiClient.debugAuthToken, isNull);
      expect(await SessionIdentityCache.load(), isNull);

      // Stragglers after the sign-out must not refresh or sign out again.
      expect(await store.refreshAccessTokenSilently(), isNull);
      expect(await store.refreshAccessTokenSilently(), isNull);
      await _settle();
      expect(store.refreshRequests, 1);
      expect(beforeSignOutCalls, 1);
    });

    test('a token the backend still rejects after refreshing ends the session',
        () async {
      final api = _ScriptedApiClient((path, _) async => throw _unauthorized());
      final store = _TestAuthStore(apiClient: api);
      var beforeSignOutCalls = 0;
      store.onBeforeSignOut = () async => beforeSignOutCalls += 1;

      await store.bootstrapFromSession();

      expect(store.refreshRequests, 1);
      expect(store.isAuthenticated, isFalse);
      expect(store.sessionEndedNotice, AuthStore.sessionEndedMessage);
      expect(beforeSignOutCalls, 1);
    });

    test('repeated rejection reports during a session sign out only once',
        () async {
      final api = _ScriptedApiClient((path, _) async {
        if (path == '/auth/session/verify') return _verified(['user']);
        return _me(['user']);
      });
      final store = _TestAuthStore(apiClient: api);
      var beforeSignOutCalls = 0;
      final unregister = Completer<void>();
      store.onBeforeSignOut = () {
        beforeSignOutCalls += 1;
        return unregister.future;
      };
      await store.bootstrapFromSession();
      expect(store.isAuthenticated, isTrue);

      store.handleSessionRejected();
      store.handleSessionRejected();
      unregister.complete();
      await _settle();
      store.handleSessionRejected();
      await _settle();

      expect(store.isAuthenticated, isFalse);
      expect(beforeSignOutCalls, 1);
    });

    test('a user sign-out leaves no session-ended notice', () async {
      final api = _ScriptedApiClient((path, _) async {
        if (path == '/auth/session/verify') return _verified(['user']);
        return _me(['user']);
      });
      final store = _TestAuthStore(apiClient: api);
      await store.bootstrapFromSession();

      await store.signOut();

      expect(store.isAuthenticated, isFalse);
      expect(store.sessionEndedNotice, isNull);
    });
  });

  group('network down', () {
    test('bootstrap keeps the session and the last known roles', () async {
      final api = _ScriptedApiClient((path, _) async => throw _offline());
      final store = _TestAuthStore(apiClient: api);
      var beforeSignOutCalls = 0;
      store.onBeforeSignOut = () async => beforeSignOutCalls += 1;
      await SessionIdentityCache.save(
        const SessionIdentity(
          userId: 'user-1',
          email: 'hunter@example.com',
          displayName: 'Hunter',
          username: 'hunter',
          roles: ['user', 'hunter'],
        ),
      );

      await store.bootstrapFromSession();

      expect(store.isAuthenticated, isTrue);
      expect(store.isBootstrapping, isFalse);
      expect(store.isSessionUnverified, isTrue);
      expect(store.roles, ['user', 'hunter']);
      expect(store.hasHunterSpace, isTrue);
      expect(store.username, 'hunter');
      expect(store.sessionEndedNotice, isNull);
      expect(beforeSignOutCalls, 0);
      expect(store.refreshRequests, 0);
      store.dispose();
    });

    test('an unreachable auth server keeps the session and backs off',
        () async {
      final api = _ScriptedApiClient((path, _) async {
        if (path == '/auth/session/verify') return _verified(['user', 'hunter']);
        return _me(['user', 'hunter']);
      });
      var now = DateTime(2026, 9, 17, 12);
      final store = _TestAuthStore(
        apiClient: api,
        refreshBackoff: RefreshBackoff(clock: () => now),
      );
      var beforeSignOutCalls = 0;
      store.onBeforeSignOut = () async => beforeSignOutCalls += 1;
      await store.bootstrapFromSession();
      expect(store.roles, ['user', 'hunter']);

      store.refresh = () async =>
          throw AuthRetryableFetchException(message: 'Failed host lookup');

      // Every screen retrying at once must not hammer Supabase.
      for (var i = 0; i < 5; i++) {
        expect(await store.refreshAccessTokenSilently(), isNull);
      }
      expect(store.refreshRequests, 1);
      expect(store.isAuthenticated, isTrue);
      expect(store.roles, ['user', 'hunter']);
      expect(store.isSessionUnverified, isTrue);
      expect(beforeSignOutCalls, 0);

      // Once the cool-down passes one more attempt is allowed.
      now = now.add(const Duration(minutes: 2));
      store.refresh = () async => 'fresh-token';
      expect(await store.refreshAccessTokenSilently(), 'fresh-token');
      expect(store.refreshRequests, 2);
      expect(store.isSessionUnverified, isFalse);
      store.dispose();
    });

    test('a failed re-verification never replaces roles', () async {
      var offline = false;
      final api = _ScriptedApiClient((path, _) async {
        if (offline) throw _offline();
        if (path == '/auth/session/verify') return _verified(['user', 'hunter']);
        return _me(['user', 'hunter']);
      });
      final store = _TestAuthStore(apiClient: api);
      await store.bootstrapFromSession();

      offline = true;
      MeSnapshotCache.reset();
      final verified = await store.verifyAndSignIn(
        'fresh-token',
        setSubmitting: false,
      );

      expect(verified, isFalse);
      expect(store.roles, ['user', 'hunter']);
      expect(store.isAuthenticated, isTrue);
    });

    test('connectivity coming back re-verifies the session', () async {
      var offline = true;
      final api = _ScriptedApiClient((path, _) async {
        if (offline) throw _offline();
        if (path == '/auth/session/verify') return _verified(['user', 'admin']);
        return _me(['user', 'admin']);
      });
      final restored = StreamController<void>.broadcast();
      final store = _TestAuthStore(
        apiClient: api,
        connectivityRestored: restored.stream,
      );
      await SessionIdentityCache.save(
        const SessionIdentity(userId: 'user-1', roles: ['user', 'hunter']),
      );

      await store.bootstrapFromSession();
      expect(store.isSessionUnverified, isTrue);
      expect(store.roles, ['user', 'hunter']);

      offline = false;
      restored.add(null);
      await _settle();

      expect(store.isSessionUnverified, isFalse);
      expect(store.roles, ['user', 'admin']);
      expect(store.isAuthenticated, isTrue);
      store.dispose();
      await restored.close();
    });
  });
}
