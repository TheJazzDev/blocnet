import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Answers 200 only for `Bearer <acceptedToken>`, 401 for everything else.
class _TokenCheckingHttpClient extends http.BaseClient {
  _TokenCheckingHttpClient({this.acceptedToken});

  final String? acceptedToken;
  final List<String> authorizations = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final authorization = request.headers['Authorization'] ?? '';
    authorizations.add(authorization);
    if (acceptedToken != null && authorization == 'Bearer $acceptedToken') {
      return _json(200, {'ok': true});
    }
    return _json(401, {
      'message': 'Invalid or expired token',
      'error': 'Unauthorized',
      'statusCode': 401,
    });
  }
}

class _OfflineHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw const SocketException('Failed host lookup: api.blocnet.test');
  }
}

http.StreamedResponse _json(int statusCode, Map<String, dynamic> body) {
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(body)));
  return http.StreamedResponse(
    Stream<List<int>>.value(bytes),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

void main() {
  var rejections = 0;

  setUp(() {
    rejections = 0;
    ApiClient.setAuthToken('stale-token');
    ApiClient.setAuthTokenRefresher(null);
    ApiClient.setSessionRejectedHandler(() => rejections += 1);
  });

  tearDown(() {
    ApiClient.setAuthToken(null);
    ApiClient.setAuthTokenRefresher(null);
    ApiClient.setSessionRejectedHandler(null);
  });

  test('a 401 followed by a successful refresh is retried transparently',
      () async {
    final httpClient = _TokenCheckingHttpClient(acceptedToken: 'fresh-token');
    var refreshes = 0;
    ApiClient.setAuthTokenRefresher(() async {
      refreshes += 1;
      return 'fresh-token';
    });

    final result = await ApiClient(httpClient: httpClient).get('/me');

    expect(result, {'ok': true});
    expect(refreshes, 1);
    expect(httpClient.authorizations, ['Bearer stale-token', 'Bearer fresh-token']);
    expect(rejections, 0);
    expect(ApiClient.debugAuthToken, 'fresh-token');
  });

  test('a 401 even after a successful refresh reports the session rejected',
      () async {
    final httpClient = _TokenCheckingHttpClient();
    ApiClient.setAuthTokenRefresher(() async => 'fresh-token');

    final error = await ApiClient(httpClient: httpClient)
        .get('/me')
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<ApiException>());
    expect(rejections, 1);
    expect(httpClient.authorizations, hasLength(2));
  });

  test('a failed refresh neither retries nor reports a rejection', () async {
    final httpClient = _TokenCheckingHttpClient();
    ApiClient.setAuthTokenRefresher(() async => null);

    final error = await ApiClient(httpClient: httpClient)
        .get('/me')
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<ApiException>());
    expect((error as ApiException).statusCode, 401);
    expect(httpClient.authorizations, hasLength(1));
    expect(rejections, 0);
  });

  test('session verify posts carry their own token and never auto-refresh',
      () async {
    final httpClient = _TokenCheckingHttpClient(acceptedToken: 'fresh-token');
    var refreshes = 0;
    ApiClient.setAuthTokenRefresher(() async {
      refreshes += 1;
      return 'fresh-token';
    });

    final error = await ApiClient(httpClient: httpClient)
        .post('/auth/session/verify', body: {'accessToken': 'stale-token'})
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<ApiException>());
    expect(refreshes, 0);
    expect(rejections, 0);
  });

  test('raw backend auth text never reaches the user', () async {
    final httpClient = _TokenCheckingHttpClient();
    ApiClient.setAuthTokenRefresher(() async => null);

    final error = await ApiClient(httpClient: httpClient)
        .get('/me')
        .then<Object?>((_) => null, onError: (Object e) => e) as ApiException;

    for (final text in [
      error.message,
      error.toString(),
      describeApiError(error),
    ]) {
      expect(text.toLowerCase(), isNot(contains('invalid or expired token')));
    }
    expect(describeApiError(error), ApiException.sessionUnconfirmedMessage);
  });

  test('describeApiError hides a raw 401 body built elsewhere', () {
    final error = ApiException(
      'Invalid or expired token',
      statusCode: 401,
      responseBody: '{"message":"Invalid or expired token"}',
    );
    expect(describeApiError(error), ApiException.sessionUnconfirmedMessage);
  });

  test('transport failures are flagged as network errors', () async {
    final error = await ApiClient(httpClient: _OfflineHttpClient())
        .get('/me')
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<ApiException>());
    expect((error as ApiException).isNetworkError, isTrue);
    expect(error.statusCode, isNull);
  });
}
