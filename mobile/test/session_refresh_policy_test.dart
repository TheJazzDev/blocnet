import 'dart:async';
import 'dart:io';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/session_refresh_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('classifyRefreshError', () {
    test('treats network-shaped failures as unreachable', () {
      final errors = <Object>[
        AuthRetryableFetchException(message: 'Failed host lookup'),
        const SocketException('Failed host lookup'),
        TimeoutException('slow'),
        http.ClientException('connection closed'),
        const HttpException('reset'),
        StateError('something odd'),
      ];
      for (final error in errors) {
        expect(
          classifyRefreshError(error),
          SessionRefreshFailure.unreachable,
          reason: '$error',
        );
      }
    });

    test('treats a rejected or missing refresh token as a dead session', () {
      final errors = <Object>[
        AuthApiException(
          'Invalid Refresh Token: Refresh Token Not Found',
          statusCode: '400',
          code: 'refresh_token_not_found',
        ),
        AuthSessionMissingException(),
        AuthException('User banned', statusCode: '403'),
      ];
      for (final error in errors) {
        expect(
          classifyRefreshError(error),
          SessionRefreshFailure.sessionDead,
          reason: '$error',
        );
      }
    });
  });

  group('classifyVerifyError', () {
    test('network and server trouble never count as a rejected session', () {
      expect(
        classifyVerifyError(ApiException('offline', isNetworkError: true)),
        SessionVerifyFailure.network,
      );
      expect(
        classifyVerifyError(ApiException('down', statusCode: 503)),
        SessionVerifyFailure.network,
      );
      expect(
        classifyVerifyError(
          ApiException(
            'x',
            statusCode: 401,
            responseBody: '{"message":"Token verification timed out"}',
          ),
        ),
        SessionVerifyFailure.network,
      );
    });

    test('a 401 is a rejected session, anything else is other', () {
      expect(
        classifyVerifyError(
          ApiException(
            'x',
            statusCode: 401,
            responseBody: '{"message":"Invalid or expired token"}',
          ),
        ),
        SessionVerifyFailure.rejected,
      );
      expect(
        classifyVerifyError(ApiException('no', statusCode: 403)),
        SessionVerifyFailure.other,
      );
      expect(classifyVerifyError(StateError('x')), SessionVerifyFailure.other);
    });
  });

  group('RefreshBackoff', () {
    test('doubles the wait after each failure up to the cap', () {
      var now = DateTime(2026, 1, 1);
      final backoff = RefreshBackoff(
        clock: () => now,
        base: const Duration(seconds: 2),
        max: const Duration(seconds: 10),
      );

      expect(backoff.isCoolingDown, isFalse);

      backoff.recordFailure();
      expect(backoff.isCoolingDown, isTrue);
      expect(backoff.remaining, const Duration(seconds: 2));

      now = now.add(const Duration(seconds: 2));
      expect(backoff.isCoolingDown, isFalse);

      backoff.recordFailure();
      expect(backoff.remaining, const Duration(seconds: 4));
      backoff.recordFailure();
      expect(backoff.remaining, const Duration(seconds: 8));
      backoff.recordFailure();
      expect(backoff.remaining, const Duration(seconds: 10));
      backoff.recordFailure();
      expect(backoff.remaining, const Duration(seconds: 10));
    });

    test('reset clears the cool-down', () {
      final backoff = RefreshBackoff();
      backoff.recordFailure();
      expect(backoff.isCoolingDown, isTrue);
      backoff.reset();
      expect(backoff.isCoolingDown, isFalse);
      expect(backoff.failures, 0);
    });
  });
}
