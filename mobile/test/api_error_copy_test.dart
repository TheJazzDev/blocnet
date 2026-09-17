import 'dart:io';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fallback = 'Something went wrong. Please try again.';

  group('describeApiError', () {
    test('shows the server message for a 4xx', () {
      final error = ApiException(
        'Request failed',
        statusCode: 400,
        responseBody: '{"message":"Amount must be positive"}',
      );
      expect(describeApiError(error), 'Amount must be positive');
    });

    test('joins a 4xx validation list into lines', () {
      final error = ApiException(
        'Request failed',
        statusCode: 400,
        responseBody: '{"message":["username is required","amount too low"]}',
      );
      expect(
        describeApiError(error),
        'username is required\namount too low',
      );
    });

    test('never shows a 5xx body or status code', () {
      final error = ApiException(
        'Request failed',
        statusCode: 500,
        responseBody:
            '{"message":"PrismaClientKnownRequestError: connection refused"}',
      );
      expect(describeApiError(error), fallback);
    });

    test('never shows a bare status code for a 4xx without a message', () {
      final error = ApiException('Request failed', statusCode: 409);
      expect(describeApiError(error), fallback);
    });

    test('network failures read as a connection problem', () {
      final error = ApiException(
        'ClientException: Failed host lookup: api.blocnet.io',
        isNetworkError: true,
      );
      expect(describeApiError(error), networkErrorMessage);
    });

    test('raw platform exceptions never reach the screen', () {
      expect(
        describeApiError(const SocketException('Connection refused')),
        networkErrorMessage,
      );
      expect(describeApiError(StateError('Bad state: no element')), fallback);
    });

    test('keeps app-authored Exception messages', () {
      expect(
        describeApiError(Exception('Pick a gem first.')),
        'Pick a gem first.',
      );
    });

    test('uses the caller fallback', () {
      expect(
        describeApiError(ApiException('x', statusCode: 502), fallback: 'Nope'),
        'Nope',
      );
    });
  });
}
