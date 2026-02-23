import 'dart:async';
import 'dart:io';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({
    ApiClient? apiClient,
    bool enableSupabaseAuthListener = true,
    bool? supabaseConfiguredOverride,
  })  : _apiClient = apiClient ?? ApiClient(),
        _enableSupabaseAuthListener = enableSupabaseAuthListener,
        _supabaseConfiguredOverride = supabaseConfiguredOverride {
    ApiClient.setAuthTokenRefresher(refreshAccessTokenSilently);

    if (_enableSupabaseAuthListener && isSupabaseConfigured) {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen(
        (event) {
          final session = event.session;
          if (session?.accessToken != null) {
            _syncAccessToken(session!.accessToken);
            _email = session.user.email;
            notifyListeners();
          }

          if (event.event == AuthChangeEvent.signedOut) {
            _clearAuth(notify: true);
          }
        },
      );
    }

    unawaited(_restorePendingReferralCode());
  }

  final ApiClient _apiClient;
  final bool _enableSupabaseAuthListener;
  final bool? _supabaseConfiguredOverride;
  StreamSubscription<AuthState>? _authSubscription;
  Future<String?>? _inFlightSilentRefresh;
  static const Duration _authTimeout = Duration(seconds: 15);
  static const Duration _spaceSwitchDelay = Duration(seconds: 2);
  static const String _spaceKeyPrefix = 'blocnet_active_space_';
  static const String _pendingReferralCodeKey = 'blocnet_pending_referral_code';

  bool _isAuthenticated = false;
  bool _isSubmitting = false;
  String? _accessToken;
  String? _userId;
  String? _email;
  String? _displayName;
  String? _avatarUrl;
  String? _bio;
  List<String> _roles = const ['user'];
  String? _username;
  DateTime? _memberSince;
  String? _walletStatus;
  String? _walletAddress;
  String? _kycStatus;
  String? _pendingReferralCode;
  String? _lastError;

  // ── Space switcher — 'user' | 'hunter' ───────────────────────────────────
  String _activeSpace = 'user';
  bool _isSwitchingSpace = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isSubmitting => _isSubmitting;
  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  String? get bio => _bio;
  String? get username => _username;
  DateTime? get memberSince => _memberSince;
  String? get walletStatus => _walletStatus;
  String? get walletAddress => _walletAddress;
  String? get kycStatus => _kycStatus;
  String? get pendingReferralCode => _pendingReferralCode;
  List<String> get roles => List.unmodifiable(_roles);
  bool get isOwner => _roles.contains('owner');
  bool get isAdmin => _roles.contains('admin');
  bool get isHunter => _roles.contains('hunter');
  bool get isUser => _roles.contains('user');
  bool get canModerateRoles => isOwner || isAdmin;
  bool get canCreateUpdate => isOwner || isAdmin || isHunter;
  bool get canSubmitProject => isOwner || isAdmin || isHunter;
  String? get lastError => _lastError;
  bool get isSupabaseConfigured =>
      _supabaseConfiguredOverride ?? AppConfig.isSupabaseConfigured;

  // ── Space switcher getters ────────────────────────────────────────────────
  /// Whether the user has any elevated role that grants hunter space access.
  bool get hasHunterSpace => isOwner || isAdmin || isHunter;

  /// The currently active space: 'user' or 'hunter'.
  String get activeSpace => _activeSpace;

  /// True when the user is viewing/interacting from the hunter perspective.
  bool get isInHunterSpace => _activeSpace == 'hunter' && hasHunterSpace;
  bool get isSwitchingSpace => _isSwitchingSpace;

  /// Toggle or set the active space. Silently ignores if the user has no
  /// hunter role — they stay in user space.
  void setActiveSpace(String space) {
    final target = (space == 'hunter' && hasHunterSpace) ? 'hunter' : 'user';
    if (_activeSpace == target) return;
    _activeSpace = target;
    unawaited(_persistActiveSpacePreference());
    notifyListeners();
  }

  void toggleSpace() {
    unawaited(
      switchSpaceWithTransition(
        _activeSpace == 'user' ? 'hunter' : 'user',
      ),
    );
  }

  Future<void> switchSpaceWithTransition(String space) async {
    final target = (space == 'hunter' && hasHunterSpace) ? 'hunter' : 'user';
    if (_activeSpace == target || _isSwitchingSpace) return;

    _isSwitchingSpace = true;
    notifyListeners();

    await Future<void>.delayed(_spaceSwitchDelay);

    _activeSpace = target;
    _isSwitchingSpace = false;
    unawaited(_persistActiveSpacePreference());
    notifyListeners();
  }

  Future<void> bootstrapFromSession() async {
    if (!isSupabaseConfigured) return;

    final bootstrapToken = await getCurrentAccessTokenForBootstrap();
    if (bootstrapToken == null || bootstrapToken.trim().isEmpty) {
      _clearAuth(notify: true);
      return;
    }

    final bootstrapSignedIn = await verifyAndSignIn(
      bootstrapToken,
      setSubmitting: false,
    );
    if (bootstrapSignedIn) {
      return;
    }

    // If startup verification fails due to an expired access token, refresh once
    // and retry before treating the local session as invalid.
    final refreshedToken = await refreshAccessTokenSilently();
    if (refreshedToken == null || refreshedToken.trim().isEmpty) {
      _clearAuth(notify: true);
      return;
    }

    final refreshedSignedIn = await verifyAndSignIn(
      refreshedToken,
      setSubmitting: false,
    );
    if (!refreshedSignedIn) {
      _clearAuth(notify: true);
    }
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_isSubmitting) return false;
    if (!isSupabaseConfigured) {
      _lastError = 'Supabase is not configured in app runtime defines';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_authTimeout);

      final session = response.session;
      if (session == null) {
        _lastError = 'No active session returned from Supabase';
        return false;
      }

      return verifyAndSignIn(session.accessToken, setSubmitting: false);
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('username') && message.contains('exist')) {
        _lastError = 'Username is already taken';
      } else {
        _lastError = error.message;
      }
      return false;
    } on TimeoutException {
      _lastError =
          'Auth request timed out after ${_authTimeout.inSeconds}s. Check your network and Supabase settings.';
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    if (_isSubmitting) return false;
    if (!isSupabaseConfigured) {
      _lastError = 'Supabase is not configured in app runtime defines';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      final normalizedReferral = _normalizeReferralCode(referralCode);
      if (normalizedReferral != null) {
        await setPendingReferralCode(normalizedReferral);
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      ).timeout(_authTimeout);

      _email = email.trim();
      final session = response.session;
      if (session == null) {
        _isAuthenticated = false;
        _lastError = null;
        return true;
      }

      return verifyAndSignIn(session.accessToken, setSubmitting: false);
    } on AuthException catch (error) {
      _lastError = error.message;
      return false;
    } on TimeoutException {
      _lastError =
          'Auth request timed out after ${_authTimeout.inSeconds}s. Check your network and Supabase settings.';
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_isSubmitting) return false;
    if (!isSupabaseConfigured) {
      _lastError = 'Supabase is not configured in app runtime defines';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.blocnet.app://login-callback',
        queryParams: const {'prompt': 'select_account'},
      ).timeout(_authTimeout);

      if (!launched) {
        _lastError = 'Failed to launch Google sign-in';
        return false;
      }

      // OAuth completion continues asynchronously via deep link callback.
      return true;
    } on AuthException catch (error) {
      _lastError = error.message;
      return false;
    } on TimeoutException {
      _lastError =
          'Auth request timed out after ${_authTimeout.inSeconds}s. Check your network and Supabase settings.';
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (_isSubmitting) return false;
    if (!isSupabaseConfigured) {
      _lastError = 'Supabase is not configured in app runtime defines';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email.trim())
          .timeout(_authTimeout);
      return true;
    } on AuthException catch (error) {
      _lastError = error.message;
      return false;
    } on TimeoutException {
      _lastError =
          'Auth request timed out after ${_authTimeout.inSeconds}s. Check your network and Supabase settings.';
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    if (_isSubmitting) return false;
    if (!isSupabaseConfigured) {
      _lastError = 'Supabase is not configured in app runtime defines';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth
          .resend(
            type: OtpType.signup,
            email: email.trim(),
          )
          .timeout(_authTimeout);
      return true;
    } on AuthException catch (error) {
      _lastError = error.message;
      return false;
    } on TimeoutException {
      _lastError =
          'Auth request timed out after ${_authTimeout.inSeconds}s. Check your network and Supabase settings.';
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    if (_isSubmitting) return false;
    if (!isSupabaseConfigured) {
      _lastError = 'Supabase is not configured in app runtime defines';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth
          .updateUser(
            UserAttributes(password: newPassword),
          )
          .timeout(_authTimeout);

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await verifyAndSignIn(session.accessToken, setSubmitting: false);
      }
      return true;
    } on AuthException catch (error) {
      _lastError = error.message;
      return false;
    } on TimeoutException {
      _lastError =
          'Auth request timed out after ${_authTimeout.inSeconds}s. Check your network and Supabase settings.';
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final nextDisplayName = displayName?.trim();
    final nextAvatarUrl = avatarUrl?.trim();
    final nextBio = bio?.trim();

    _displayName =
        nextDisplayName?.isNotEmpty == true ? nextDisplayName : _displayName;
    _avatarUrl = nextAvatarUrl?.isNotEmpty == true ? nextAvatarUrl : _avatarUrl;
    _bio = nextBio ?? _bio;
    notifyListeners();

    try {
      await _apiClient.patch(
        '/me',
        body: {
          if (nextDisplayName != null) 'displayName': nextDisplayName,
          if (nextAvatarUrl != null) 'avatarUrl': nextAvatarUrl,
          if (nextBio != null) 'bio': nextBio,
        },
      );
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatarImage(File file) async {
    if (!await file.exists()) {
      _lastError = 'Selected image file no longer exists';
      notifyListeners();
      return false;
    }

    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      _lastError = 'Avatar must be 5MB or smaller';
      notifyListeners();
      return false;
    }

    try {
      final response = await _apiClient.postMultipartFile(
        '/me/avatar',
        fieldName: 'file',
        file: file,
      );
      if (response is! Map<String, dynamic>) {
        _lastError = 'Unexpected avatar upload response';
        notifyListeners();
        return false;
      }

      final avatarUrl = response['avatarUrl']?.toString();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        _avatarUrl = avatarUrl;
      }

      _lastError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _lastError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyAndSignIn(
    String accessToken, {
    bool setSubmitting = true,
  }) async {
    if (_isSubmitting && setSubmitting) return false;

    final token = accessToken.trim();
    if (token.isEmpty) {
      _lastError = 'Access token is required';
      notifyListeners();
      return false;
    }

    if (setSubmitting) {
      _isSubmitting = true;
      _lastError = null;
      notifyListeners();
    }

    try {
      final response = await _apiClient.post(
        '/auth/session/verify',
        body: {'accessToken': token},
      );

      if (response is! Map<String, dynamic>) {
        _lastError = 'Unexpected auth response';
        return false;
      }

      final user = response['user'];
      if (user is! Map<String, dynamic>) {
        _lastError = 'Invalid auth response';
        return false;
      }

      _syncAccessToken(token);
      _userId = user['id']?.toString();
      _email = user['email']?.toString() ?? _email;
      _roles = _parseRoles(user['roles']);

      await _hydrateProfileFromMe();
      await _attemptPendingReferralBind();
      await _restoreActiveSpacePreference();
      if (!hasHunterSpace) {
        _activeSpace = 'user';
      }
      _isAuthenticated = true;
      _lastError = null;
      return true;
    } on ApiException catch (error) {
      _lastError = error.responseBody?.isNotEmpty == true
          ? error.responseBody
          : error.message;
      return false;
    } catch (error) {
      _lastError = error.toString();
      return false;
    } finally {
      if (setSubmitting) {
        _isSubmitting = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    if (isSupabaseConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Fall through and clear local auth state.
      }
    }
    _clearAuth(notify: true);
  }

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
          .timeout(_authTimeout);

      final session =
          response.session ?? Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null || token.trim().isEmpty) {
        return null;
      }

      _syncAccessToken(token);
      _email = session?.user.email ?? _email;
      return token;
    } catch (_) {
      return null;
    }
  }

  void _syncAccessToken(String token) {
    _accessToken = token;
    ApiClient.setAuthToken(token);
  }

  void _clearAuth({required bool notify}) {
    _accessToken = null;
    _userId = null;
    _email = null;
    _displayName = null;
    _avatarUrl = null;
    _bio = null;
    _username = null;
    _memberSince = null;
    _walletStatus = null;
    _walletAddress = null;
    _kycStatus = null;
    _roles = const ['user'];
    _isAuthenticated = false;
    _lastError = null;
    _activeSpace = 'user';
    ApiClient.setAuthToken(null);
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ApiClient.setAuthTokenRefresher(null);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _hydrateProfileFromMe() async {
    try {
      final response = await _apiClient.get('/me');
      if (response is! Map<String, dynamic>) return;

      _displayName = response['displayName']?.toString() ?? _displayName;
      _avatarUrl = response['avatarUrl']?.toString() ?? _avatarUrl;
      _bio = response['bio']?.toString() ?? _bio;
      _username = response['username']?.toString() ?? _username;
      _walletStatus = response['walletStatus']?.toString() ?? _walletStatus;
      _walletAddress = response['walletAddress']?.toString() ?? _walletAddress;
      _kycStatus = response['kycStatus']?.toString() ?? _kycStatus;

      final rawMemberSince = response['createdAt'] ?? response['memberSince'];
      if (rawMemberSince != null) {
        _memberSince = DateTime.tryParse(rawMemberSince.toString());
      }

      final responseRoles = _parseRoles(response['roles']);
      if (responseRoles.isNotEmpty) {
        _roles = responseRoles;
      }
    } catch (_) {
      // Keep auth successful even when profile enrichment fails.
    }
  }

  Future<void> setPendingReferralCode(String? code) async {
    final normalized = _normalizeReferralCode(code);
    _pendingReferralCode = normalized;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (normalized == null) {
        await prefs.remove(_pendingReferralCodeKey);
      } else {
        await prefs.setString(_pendingReferralCodeKey, normalized);
      }
    } catch (_) {
      // Ignore storage failures and keep in-memory state.
    }
  }

  Future<void> _restorePendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingReferralCode = _normalizeReferralCode(
        prefs.getString(_pendingReferralCodeKey),
      );
      notifyListeners();
    } catch (_) {
      _pendingReferralCode = null;
    }
  }

  Future<void> _attemptPendingReferralBind() async {
    final pending = _pendingReferralCode;
    if (!_isAuthenticated || pending == null || pending.isEmpty) {
      return;
    }

    try {
      await _apiClient.post('/referrals/bind', body: {'code': pending});
      await setPendingReferralCode(null);
    } on ApiException catch (error) {
      final body = (error.responseBody ?? '').toLowerCase();
      // Clear locally if code is no longer bindable for this account.
      if (error.statusCode == 400 ||
          error.statusCode == 404 ||
          error.statusCode == 409 ||
          body.contains('already') ||
          body.contains('expired') ||
          body.contains('not found') ||
          body.contains('invalid')) {
        await setPendingReferralCode(null);
      }
    } catch (_) {
      // Keep pending value and retry on next authenticated session.
    }
  }

  String? _normalizeReferralCode(String? value) {
    final trimmed = value?.trim().toUpperCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Future<void> _restoreActiveSpacePreference() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('$_spaceKeyPrefix$userId');
      if (saved == 'hunter' && hasHunterSpace) {
        _activeSpace = 'hunter';
      } else {
        _activeSpace = 'user';
      }
    } catch (_) {
      _activeSpace = 'user';
    }
  }

  Future<void> _persistActiveSpacePreference() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_spaceKeyPrefix$userId', _activeSpace);
    } catch (_) {
      // Ignore persistence failure; runtime state still updates.
    }
  }

  List<String> _parseRoles(dynamic input) {
    if (input is! List) {
      return _roles;
    }

    final normalized = input
        .map((value) => value.toString().trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (normalized.isEmpty) {
      return const ['user'];
    }

    return normalized;
  }
}
