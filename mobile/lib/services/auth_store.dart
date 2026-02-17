import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';
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

  bool _isAuthenticated = false;
  bool _isSubmitting = false;
  String? _accessToken;
  String? _userId;
  String? _email;
  String? _displayName;
  String? _avatarUrl;
  List<String> _roles = const ['user'];
  String? _username;
  DateTime? _memberSince;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  bool get isSubmitting => _isSubmitting;
  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  String? get username => _username;
  DateTime? get memberSince => _memberSince;
  List<String> get roles => List.unmodifiable(_roles);
  bool get isOwner => _roles.contains('owner');
  bool get isAdmin => _roles.contains('admin');
  bool get isPoster => _roles.contains('poster');
  bool get isUser => _roles.contains('user');
  bool get canModerateRoles => isOwner || isAdmin;
  bool get canCreateUpdate => isOwner || isAdmin || isPoster;
  bool get canSubmitProject => isOwner || isAdmin || isPoster;
  String? get lastError => _lastError;
  bool get isSupabaseConfigured => AppConfig.isSupabaseConfigured;

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
    _roles = const ['user'];
    _isAuthenticated = false;
    _lastError = null;
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
      _username = response['username']?.toString() ?? _username;

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
