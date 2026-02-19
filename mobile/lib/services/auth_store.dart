import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStore extends ChangeNotifier {
  AuthStore() {
    if (AppConfig.isSupabaseConfigured) {
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
  }

  final ApiClient _apiClient = ApiClient();
  StreamSubscription<AuthState>? _authSubscription;
  static const Duration _authTimeout = Duration(seconds: 15);
  static const String _spaceKeyPrefix = 'blocnet_active_space_';

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
  String? _lastError;

  // ── Space switcher — 'user' | 'hunter' ───────────────────────────────────
  String _activeSpace = 'user';

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
  List<String> get roles => List.unmodifiable(_roles);
  bool get isOwner => _roles.contains('owner');
  bool get isAdmin => _roles.contains('admin');
  bool get isHunter => _roles.contains('hunter');
  bool get isUser => _roles.contains('user');
  bool get canModerateRoles => isOwner || isAdmin;
  bool get canCreateUpdate => isOwner || isAdmin || isHunter;
  bool get canSubmitProject => isOwner || isAdmin || isHunter;
  String? get lastError => _lastError;
  bool get isSupabaseConfigured => AppConfig.isSupabaseConfigured;

  // ── Space switcher getters ────────────────────────────────────────────────
  /// Whether the user has any elevated role that grants hunter space access.
  bool get hasHunterSpace => isOwner || isAdmin || isHunter;

  /// The currently active space: 'user' or 'hunter'.
  String get activeSpace => _activeSpace;

  /// True when the user is viewing/interacting from the hunter perspective.
  bool get isInHunterSpace => _activeSpace == 'hunter' && hasHunterSpace;

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
    setActiveSpace(_activeSpace == 'user' ? 'hunter' : 'user');
  }

  Future<void> bootstrapFromSession() async {
    if (!isSupabaseConfigured) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _clearAuth(notify: true);
      return;
    }

    await verifyAndSignIn(session.accessToken, setSubmitting: false);
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
