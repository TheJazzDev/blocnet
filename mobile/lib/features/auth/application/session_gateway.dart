import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class SessionGateway {
  SessionGateway({
    required bool isSupabaseConfigured,
    required this.authTimeout,
    required this.syncAccessToken,
    required this.setEmail,
  }) : _isSupabaseConfigured = isSupabaseConfigured;

  final bool _isSupabaseConfigured;
  final Duration authTimeout;
  final void Function(String token) syncAccessToken;
  final void Function(String? email) setEmail;

  Future<String?>? _inFlightSilentRefresh;

  bool get isSupabaseConfigured => _isSupabaseConfigured;

  Future<String?> getCurrentAccessTokenForBootstrap() async {
    if (!isSupabaseConfigured) {
      return null;
    }
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  Future<String?> refreshAccessTokenSilently() async {
    if (!isSupabaseConfigured) {
      return null;
    }

    final pending = _inFlightSilentRefresh;
    if (pending != null) {
      return pending;
    }

    final refreshFuture = _refreshAccessTokenSilentlyInternal();
    _inFlightSilentRefresh = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_inFlightSilentRefresh, refreshFuture)) {
        _inFlightSilentRefresh = null;
      }
    }
  }

  Future<String?> _refreshAccessTokenSilentlyInternal() async {
    if (!isSupabaseConfigured) {
      return null;
    }

    try {
      final response = await Supabase.instance.client.auth
          .refreshSession()
          .timeout(authTimeout);

      final session =
          response.session ?? Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null || token.trim().isEmpty) {
        return null;
      }

      syncAccessToken(token);
      setEmail(session?.user.email);
      return token;
    } catch (_) {
      return null;
    }
  }
}
