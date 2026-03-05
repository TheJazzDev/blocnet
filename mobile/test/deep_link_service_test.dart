import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _DeepLinkAuthStore extends AuthStore {
  _DeepLinkAuthStore()
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  String? verifiedAccessToken;
  String? savedReferralCode;

  @override
  Future<void> setPendingReferralCode(String? code) async {
    savedReferralCode = code;
  }

  @override
  Future<bool> verifyAndSignIn(
    String accessToken, {
    bool setSubmitting = true,
    bool hydrateProfile = true,
    bool bindPendingReferral = true,
  }) async {
    verifiedAccessToken = accessToken;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('token callback consumes refresh token and verifies with session token',
      () async {
    final authStore = _DeepLinkAuthStore();
    String? consumedRefreshToken;

    final service = DeepLinkService(
      navigatorKey: GlobalKey<NavigatorState>(),
      authStore: authStore,
      setSessionWithRefreshToken: (refreshToken) async {
        consumedRefreshToken = refreshToken;

        final user = User(
          id: 'user-1',
          appMetadata: const <String, dynamic>{},
          userMetadata: const <String, dynamic>{},
          aud: 'authenticated',
          createdAt: DateTime(2024, 1, 1).toIso8601String(),
        );
        return AuthResponse(
          session: Session(
            accessToken: 'session-access-token',
            refreshToken: 'rotated-refresh-token',
            tokenType: 'bearer',
            user: user,
          ),
        );
      },
    );

    await service.handleUriForTesting(
      Uri.parse(
        'io.blocnet.app://#access_token=url-access-token&refresh_token=url-refresh-token&type=signup',
      ),
    );

    expect(consumedRefreshToken, 'url-refresh-token');
    expect(authStore.verifiedAccessToken, 'session-access-token');
  });

  test('https auth callback consumes refresh token and verifies session',
      () async {
    final authStore = _DeepLinkAuthStore();
    String? consumedRefreshToken;

    final service = DeepLinkService(
      navigatorKey: GlobalKey<NavigatorState>(),
      authStore: authStore,
      setSessionWithRefreshToken: (refreshToken) async {
        consumedRefreshToken = refreshToken;

        final user = User(
          id: 'user-2',
          appMetadata: const <String, dynamic>{},
          userMetadata: const <String, dynamic>{},
          aud: 'authenticated',
          createdAt: DateTime(2024, 1, 1).toIso8601String(),
        );
        return AuthResponse(
          session: Session(
            accessToken: 'session-access-token-https',
            refreshToken: 'rotated-refresh-token-https',
            tokenType: 'bearer',
            user: user,
          ),
        );
      },
    );

    await service.handleUriForTesting(
      Uri.parse(
        'https://blocnet.app/auth/callback#access_token=url-access-token&refresh_token=url-refresh-token&type=signup',
      ),
    );

    expect(consumedRefreshToken, 'url-refresh-token');
    expect(authStore.verifiedAccessToken, 'session-access-token-https');
  });

  test('referral path stores pending code', () async {
    final authStore = _DeepLinkAuthStore();
    final service = DeepLinkService(
      navigatorKey: GlobalKey<NavigatorState>(),
      authStore: authStore,
      setSessionWithRefreshToken: (refreshToken) async {
        throw UnimplementedError();
      },
    );

    await service.handleUriForTesting(
      Uri.parse('https://blocnet.app/ref/AB12CD34'),
    );

    expect(authStore.savedReferralCode, 'AB12CD34');
  });
}
