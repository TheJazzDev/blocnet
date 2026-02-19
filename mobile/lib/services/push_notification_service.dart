import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/services/api/api_client.dart';

/// Handles FCM token registration, permission requests, and foreground
/// notification display. Call [init] once after the user is authenticated.
class PushNotificationService {
  PushNotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Request permission, fetch token, register with backend, and set up
  /// foreground message handling. Safe to call multiple times — only
  /// registers subscriptions once.
  Future<void> init() async {
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

    // On iOS, request the APNs token first (no-op on Android).
    if (Platform.isIOS) {
      await _messaging.getAPNSToken();
    }

    // Get the current FCM token and register it.
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Re-register whenever the token rotates.
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(_registerToken);

    // Handle messages that arrive while the app is in the foreground.
    _foregroundSub ??= FirebaseMessaging.onMessage.listen(_onForegroundMessage);
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

  void _onForegroundMessage(RemoteMessage message) {
    // Firebase does NOT show a notification banner when the app is in the
    // foreground on Android. On iOS, foreground banners require explicit
    // presentation options set below. We log here; the [NotificationsStore]
    // refresh on app resume will pick up the in-app record created by the
    // backend broadcast.
    debugPrint(
      '[PushNotificationService] Foreground message: '
      '${message.notification?.title}',
    );
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
