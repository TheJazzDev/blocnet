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
  final Future<AuthResponse> Function(String refreshToken)
      _setSessionWithRefreshToken;

  StreamSubscription<Uri>? _sub;

  DeepLinkService({
    required this.navigatorKey,
    required this.authStore,
    Future<AuthResponse> Function(String refreshToken)?
        setSessionWithRefreshToken,
  }) : _setSessionWithRefreshToken = setSessionWithRefreshToken ??
            Supabase.instance.client.auth.setSession;

  /// Call once from main.dart after runApp
  void init() {
    // Handle link that launched the app from a cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        unawaited(_handleUri(uri));
      }
    });

    // Handle links while app is already running
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleUri(uri)),
      onError: (_) {}, // silently ignore malformed URIs
    );
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _handleUri(Uri uri) async {
    final isAppScheme = uri.scheme == 'io.blocnet.app';
    final isSupabaseVerifyLink =
        (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.path.contains('/auth/v1/verify');
    if (!isAppScheme && !isSupabaseVerifyLink) return;

    // Capture referral links like io.blocnet.app://signup?ref=AB12CD34
    if (isAppScheme) {
      final rawReferralCode = uri.queryParameters['ref'];
      if (rawReferralCode != null && rawReferralCode.trim().isNotEmpty) {
        await authStore.setPendingReferralCode(rawReferralCode);
      }
    }

    // Supabase sends auth callbacks in two formats:
    // 1. Hash fragment: io.blocnet.app://#access_token=xxx&refresh_token=yyy&type=signup
    // 2. Query params: io.blocnet.app://?code=xxx (email confirmation)

    Map<String, String> params = {};

    // Try fragment first (magic links, OAuth)
    if (isAppScheme && uri.fragment.isNotEmpty) {
      params = Uri.splitQueryString(uri.fragment);
    }
    // Fall back to query params (email confirmation)
    else if (uri.queryParameters.isNotEmpty) {
      params = uri.queryParameters;
    }

    if (params.isEmpty) return;

    final type = params['type']?.toLowerCase();
    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];
    final code = params['code']; // OAuth PKCE / email verification code
    final tokenHash = params['token_hash'] ?? params['token'];

    // Handle auth code:
    // 1) Try OAuth PKCE exchange first.
    // 2) Fall back to email verification OTP.
    if (code != null) {
      try {
        final oauth =
            await Supabase.instance.client.auth.exchangeCodeForSession(
          code,
        );
        final success = await authStore.verifyAndSignIn(
          oauth.session.accessToken,
        );
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          success ? AppRoutes.main : AppRoutes.signIn,
          (route) => false,
        );
        return;
      } catch (_) {
        // Ignore and try email OTP fallback.
      }

      try {
        final otpType = _resolveOtpType(type) ?? OtpType.email;
        final otp = await Supabase.instance.client.auth.verifyOTP(
          token: code,
          type: otpType,
        );

        if (otp.session != null) {
          if (otpType == OtpType.recovery) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.resetPassword,
              (route) => false,
              arguments: {'accessToken': otp.session!.accessToken},
            );
          } else {
            final success = await authStore.verifyAndSignIn(
              otp.session!.accessToken,
            );
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              success ? AppRoutes.main : AppRoutes.signIn,
              (route) => false,
            );
          }
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
      return;
    }

    // Handle token-hash email links (signup/recovery) that may not include
    // access/refresh tokens in the callback URL.
    if (tokenHash != null &&
        tokenHash.trim().isNotEmpty &&
        accessToken == null &&
        refreshToken == null) {
      final otpType = _resolveOtpType(type);
      if (otpType != null) {
        try {
          final otp = await Supabase.instance.client.auth.verifyOTP(
            tokenHash: tokenHash,
            type: otpType,
          );
          final session = otp.session;
          if (session != null) {
            if (otpType == OtpType.recovery) {
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.resetPassword,
                (route) => false,
                arguments: {'accessToken': session.accessToken},
              );
            } else {
              final success = await authStore.verifyAndSignIn(
                session.accessToken,
              );
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                success ? AppRoutes.main : AppRoutes.signIn,
                (route) => false,
              );
            }
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
      return;
    }

    // Handle token-based auth (magic links, OAuth)
    if (accessToken == null || refreshToken == null) return;

    try {
      // Let Supabase consume and persist the rotated session from refresh token.
      final authResponse = await _setSessionWithRefreshToken(refreshToken);
      final sessionAccessToken =
          authResponse.session?.accessToken ?? accessToken;

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
      final success = await authStore.verifyAndSignIn(sessionAccessToken);
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

  OtpType? _resolveOtpType(String? type) {
    switch (type) {
      case 'signup':
        return OtpType.signup;
      case 'recovery':
        return OtpType.recovery;
      case 'magiclink':
        return OtpType.magiclink;
      case 'invite':
        return OtpType.invite;
      case 'email':
        return OtpType.email;
      case 'email_change':
        return OtpType.emailChange;
      case 'phone_change':
        return OtpType.phoneChange;
      case 'sms':
        return OtpType.sms;
      default:
        return null;
    }
  }

  Future<void> handleUriForTesting(Uri uri) => _handleUri(uri);
}
