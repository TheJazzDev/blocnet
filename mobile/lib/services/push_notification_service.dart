import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/services/api/api_client.dart';

/// Handles FCM token registration, permission requests, and foreground
/// notification display. Call [init] once after the user is authenticated.
class PushNotificationService {
  PushNotificationService({
    ApiClient? apiClient,
    VoidCallback? onForegroundMessage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _onForegroundMessageCallback = onForegroundMessage;

  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final VoidCallback? _onForegroundMessageCallback;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;
  static const int _apnsMaxAttempts = 8;
  static const Duration _apnsPollInterval = Duration(seconds: 1);

  /// Request permission, fetch token, register with backend, and set up
  /// foreground message handling. Safe to call multiple times — only
  /// registers subscriptions once.
  Future<void> init() async {
    try {
      // Request permission (iOS prompts dialog; Android 13+ also needs this).
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = settings.authorizationStatus;
      if (status == AuthorizationStatus.denied) {
        // User declined — we won't register a token but won't crash.
        return;
      }

      // On iOS, APNS may not be immediately available at startup.
      // We wait briefly, then continue gracefully even if still unavailable.
      if (Platform.isIOS) {
        final hasApns = await _waitForApnsToken();
        if (!hasApns) {
          debugPrint(
            '[PushNotificationService] APNS token not ready; '
            'skipping immediate FCM token fetch.',
          );
        }
      }

      await _registerCurrentFcmTokenBestEffort();

      // Re-register whenever the token rotates.
      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(
        _registerToken,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            '[PushNotificationService] onTokenRefresh stream error: $error',
          );
        },
      );

      // Handle messages that arrive while the app is in the foreground.
      _foregroundSub ??=
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (error) {
      // Push registration is best-effort and must never crash app startup.
      debugPrint('[PushNotificationService] init failed: $error');
    }
  }

  /// Release subscriptions. Call when the user signs out.
  void dispose() {
    _foregroundSub?.cancel();
    _foregroundSub = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _registerCurrentFcmTokenBestEffort() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }
    } on FirebaseException catch (error) {
      if (_isApnsNotReadyError(error)) {
        // Common on iOS simulator and during very early startup.
        debugPrint(
          '[PushNotificationService] FCM token unavailable yet (${error.code}).',
        );
        return;
      }
      debugPrint(
        '[PushNotificationService] getToken FirebaseException: '
        '${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('[PushNotificationService] getToken failed: $error');
    }
  }

  Future<bool> _waitForApnsToken() async {
    if (!Platform.isIOS) return true;

    for (var attempt = 0; attempt < _apnsMaxAttempts; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          return true;
        }
      } on FirebaseException catch (error) {
        if (!_isApnsNotReadyError(error)) {
          debugPrint(
            '[PushNotificationService] getAPNSToken FirebaseException: '
            '${error.code} ${error.message}',
          );
          return false;
        }
      } catch (error) {
        debugPrint('[PushNotificationService] getAPNSToken failed: $error');
        return false;
      }

      await Future.delayed(_apnsPollInterval);
    }

    return false;
  }

  bool _isApnsNotReadyError(FirebaseException error) {
    return error.code == 'apns-token-not-set';
  }

  Future<void> _registerToken(String token) async {
    try {
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'web';

      await _apiClient.post(
        '/device-tokens/register',
        body: {'token': token, 'platform': platform},
      );
    } catch (_) {
      // Best-effort — a failed registration is non-fatal. The token will be
      // retried on the next app launch via [onTokenRefresh].
      debugPrint('[PushNotificationService] Token registration failed');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Firebase does NOT show a notification banner when the app is in the
    // foreground on Android. On iOS, foreground banners require explicit
    // presentation options set below. We log and trigger a store refresh so
    // the in-app inbox updates immediately.
    debugPrint(
      '[PushNotificationService] Foreground message: '
      '${message.notification?.title}',
    );

    try {
      _onForegroundMessageCallback?.call();
    } catch (error) {
      debugPrint(
        '[PushNotificationService] Foreground refresh callback failed: $error',
      );
    }
  }
}

/// Top-level background message handler required by firebase_messaging.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to call Firebase.initializeApp() here — it is already initialised
  // in main() before runApp. We simply log; the in-app record will be fetched
  // on next foreground.
  debugPrint(
    '[FCM Background] ${message.notification?.title}: '
    '${message.notification?.body}',
  );
}
