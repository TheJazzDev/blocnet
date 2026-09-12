import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Every `ApiClient()` used to build its own `http.Client`, which on mobile
/// means its own `HttpClient` and therefore its own TCP/TLS connection pool.
/// With ~31 instantiations across the stores and repositories, opening a screen
/// paid a fresh DNS + TCP + TLS handshake before its first request could start.
/// Sharing one client is what lets keep-alive actually keep anything alive.
void main() {
  group('ApiClient transport sharing', () {
    test('two default instances share one http.Client', () {
      expect(identical(ApiClient().httpClient, ApiClient().httpClient), isTrue);
    });

    test('the shared client survives across many instantiations', () {
      final first = ApiClient().httpClient;
      final clients = List.generate(31, (_) => ApiClient().httpClient);

      expect(clients.every((client) => identical(client, first)), isTrue);
    });

    test('an explicitly injected client is still honoured', () {
      final injected = http.Client();
      addTearDown(injected.close);

      expect(identical(ApiClient(httpClient: injected).httpClient, injected),
          isTrue);
    });

    test('injecting a client does not replace the shared default', () {
      final injected = http.Client();
      addTearDown(injected.close);

      ApiClient(httpClient: injected);

      expect(identical(ApiClient().httpClient, injected), isFalse);
    });
  });
}
