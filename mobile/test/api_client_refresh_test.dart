import 'dart:convert';
import 'dart:typed_data';

import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _RetryingHttpClient extends http.BaseClient {
  int staleTokenAttempts = 0;
  int freshTokenAttempts = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final authorization = request.headers['Authorization'] ?? '';
    if (authorization == 'Bearer stale-token') {
      staleTokenAttempts += 1;
      return _jsonResponse(401, {'message': 'expired'});
    }

    if (authorization == 'Bearer fresh-token') {
      freshTokenAttempts += 1;
      return _jsonResponse(200, {'ok': true});
    }

    return _jsonResponse(401, {'message': 'missing auth'});
  }

  http.StreamedResponse _jsonResponse(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  setUp(() {
    ApiClient.setAuthToken('stale-token');
    ApiClient.setAuthTokenRefresher(null);
  });

  tearDown(() {
    ApiClient.setAuthToken(null);
    ApiClient.setAuthTokenRefresher(null);
  });

  test('concurrent 401 retries share one token refresh', () async {
    final httpClient = _RetryingHttpClient();
    final apiClient = ApiClient(httpClient: httpClient);
    var refreshCalls = 0;

    ApiClient.setAuthTokenRefresher(() async {
      refreshCalls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return 'fresh-token';
    });

    final results = await Future.wait<dynamic>([
      apiClient.get('/resource-a'),
      apiClient.get('/resource-b'),
    ]);

    expect(refreshCalls, 1);
    expect(httpClient.staleTokenAttempts, 2);
    expect(httpClient.freshTokenAttempts, 2);
    expect(results, everyElement({'ok': true}));
  });
}
