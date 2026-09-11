import 'dart:io';

import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/foundation.dart';

/// Owns the lifecycle of the FCM device token row on the backend.
///
/// Split out of [PushNotificationService] so the register/unregister contract
/// can be exercised without a live Firebase instance: this class only talks to
/// [ApiClient] and holds the token value it last registered.
///
/// Backend contract (`backend/src/device-tokens/`):
///  * `POST /device-tokens/register` — upserts `{token, platform}` for the
///    calling user.
///  * `DELETE /device-tokens?token=<value>` — deletes by token value, scoped to
///    the caller. An unknown token, or one owned by someone else, comes back as
///    `{deleted: false}` rather than an error.
class DeviceTokenRegistrar {
  DeviceTokenRegistrar({
    ApiClient? apiClient,
    String Function()? platformResolver,
  })  : _apiClient = apiClient ?? ApiClient(),
        _platformResolver = platformResolver ?? _defaultPlatform;

  final ApiClient _apiClient;
  final String Function() _platformResolver;

  String? _currentToken;

  /// The token value most recently sent to `/device-tokens/register`.
  ///
  /// Retained so sign-out can unregister it — the client never sees the
  /// `DeviceToken` row id, only the value FCM handed it.
  String? get currentToken => _currentToken;

  /// Register [token] with the backend. Best-effort: a failure is logged and
  /// swallowed, because push registration must never break a sign-in.
  Future<void> register(String token) async {
    if (token.isEmpty) return;

    try {
      await _apiClient.post(
        '/device-tokens/register',
        body: {'token': token, 'platform': _platformResolver()},
      );
      _currentToken = token;
    } catch (error) {
      debugPrint('[DeviceTokenRegistrar] register failed: $error');
    }
  }

  /// FCM rotated the token: drop the stale row before claiming the new value,
  /// otherwise the old token keeps receiving push for this account.
  Future<void> handleTokenRefresh(String token) async {
    final previous = _currentToken;
    if (previous != null && previous.isNotEmpty && previous != token) {
      await _unregister(previous);
    }
    await register(token);
  }

  /// Unregister the retained token. Called on sign-out *before* the auth token
  /// is cleared — the request is authenticated as the user who is leaving.
  ///
  /// Never throws: sign-out must complete even with no network.
  Future<void> unregisterCurrentToken() async {
    final token = _currentToken;
    if (token == null || token.isEmpty) return;

    _currentToken = null;
    await _unregister(token);
  }

  Future<void> _unregister(String token) async {
    try {
      await _apiClient.delete('/device-tokens', query: {'token': token});
    } catch (error) {
      debugPrint('[DeviceTokenRegistrar] unregister failed: $error');
    }
  }

  static String _defaultPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }
}
