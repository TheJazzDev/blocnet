import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthStore authStore;

  StreamSubscription<Uri>? _sub;

  DeepLinkService({
    required this.navigatorKey,
    required this.authStore,
  });

  /// Call once from main.dart after runApp
  void init() {
    // Handle link that launched the app from a cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // Handle links while app is already running
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {}, // silently ignore malformed URIs
    );
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleUri(Uri uri) async {
    // Only handle our scheme
    if (uri.scheme != 'io.blocnet.app') return;

    final fragment = uri.fragment; // e.g. access_token=xxx&type=signup
    if (fragment.isEmpty) return;

    final params = Uri.splitQueryString(fragment);
    final type = params['type'];
    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];

    if (accessToken == null || refreshToken == null) return;

    try {
      // Let Supabase consume the tokens from the URL
      await Supabase.instance.client.auth.setSession(accessToken);

      if (type == 'recovery') {
        // Password reset — navigate to reset password screen
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.resetPassword,
          (route) => false,
          arguments: {'accessToken': accessToken},
        );
        return;
      }

      // Email confirmation or magic link — sign in
      final success = await authStore.verifyAndSignIn(accessToken);
      if (success) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.main,
          (route) => false,
        );
      } else {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (route) => false,
        );
      }
    } catch (_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (route) => false,
      );
    }
  }
}
