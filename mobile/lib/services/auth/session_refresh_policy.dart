import 'dart:math' as math;

import 'package:blocnet/services/api/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a Supabase session refresh failed.
enum SessionRefreshFailure {
  /// The refresh token was rejected, expired, revoked or is gone. Nothing the
  /// app retries can bring this session back; the user has to sign in again.
  sessionDead,

  /// The auth server could not be reached (DNS, socket, timeout, 5xx). The
  /// session may be perfectly fine, so it must be kept.
  unreachable,
}

/// Classifies a refresh error the same way Supabase does internally: it drops
/// the stored session for every [AuthException] except
/// [AuthRetryableFetchException]. Anything we do not recognise is treated as
/// unreachable, because wrongly signing someone out is worse than retrying.
SessionRefreshFailure classifyRefreshError(Object error) {
  if (error is AuthRetryableFetchException) {
    return SessionRefreshFailure.unreachable;
  }
  if (error is AuthException) return SessionRefreshFailure.sessionDead;
  return SessionRefreshFailure.unreachable;
}

/// Why `POST /auth/session/verify` failed.
enum SessionVerifyFailure {
  /// No usable answer: offline, timed out, or the backend itself is in
  /// trouble. Keep the session.
  network,

  /// The backend looked at the token and refused it.
  rejected,

  /// Any other failure (unexpected payload, 403, ...).
  other,
}

SessionVerifyFailure classifyVerifyError(Object error) {
  if (error is! ApiException) return SessionVerifyFailure.other;
  if (error.isNetworkError) return SessionVerifyFailure.network;
  final status = error.statusCode;
  if (status != null && status >= 500) return SessionVerifyFailure.network;
  if (status == 401) {
    return isServerSideAuthTrouble(error.responseBody)
        ? SessionVerifyFailure.network
        : SessionVerifyFailure.rejected;
  }
  return SessionVerifyFailure.other;
}

/// Exponential back-off for refresh attempts after the auth server was
/// unreachable, so a screen full of failing requests cannot turn into a
/// refresh loop against Supabase.
class RefreshBackoff {
  RefreshBackoff({
    DateTime Function()? clock,
    this.base = const Duration(seconds: 2),
    this.max = const Duration(seconds: 60),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration base;
  final Duration max;

  int _failures = 0;
  DateTime? _retryAt;

  int get failures => _failures;

  /// Time left before another attempt is allowed, or null when allowed now.
  Duration? get remaining {
    final retryAt = _retryAt;
    if (retryAt == null) return null;
    final left = retryAt.difference(_clock());
    return left > Duration.zero ? left : null;
  }

  bool get isCoolingDown => remaining != null;

  /// The wait the next failure would impose.
  Duration get nextDelay {
    final exponent = math.min(_failures, 20);
    final millis = base.inMilliseconds * math.pow(2, exponent);
    return Duration(milliseconds: math.min(millis.toInt(), max.inMilliseconds));
  }

  void recordFailure() {
    final delay = nextDelay;
    _failures += 1;
    _retryAt = _clock().add(delay);
  }

  void reset() {
    _failures = 0;
    _retryAt = null;
  }
}
