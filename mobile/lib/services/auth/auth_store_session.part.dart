part of 'auth_store.dart';

/// Session health: tells a dead session (sign out, route to sign-in) apart
/// from an unreachable server (keep the session and the last known roles,
/// retry later). See F-38.
extension _AuthStoreSessionExt on AuthStore {
  bool get _hasLocalSession =>
      _isAuthenticated || (_accessToken?.isNotEmpty ?? false);

  Future<bool> _verifyQuietly(String token) {
    return verifyAndSignIn(
      token,
      setSubmitting: false,
      hydrateProfile: false,
      bindPendingReferral: false,
    );
  }

  /// Verifies [token] with the backend and settles what a failure means.
  /// Returns true only when the backend confirmed the session. On false the
  /// store is either signed out (dead session) or running unverified.
  Future<bool> _confirmSession(String token) async {
    if (await _verifyQuietly(token)) return true;
    if (!_hasLocalSession) return false;
    if (_lastVerifyFailure != SessionVerifyFailure.rejected) {
      await _enterUnverifiedSession();
      return false;
    }

    // The access token was refused: refresh once and try again.
    final refreshed = await refreshAccessTokenSilently();
    await _pendingSessionEnd;
    if (!_hasLocalSession) return false;
    if (refreshed == null || refreshed.trim().isEmpty) {
      await _enterUnverifiedSession();
      return false;
    }

    if (await _verifyQuietly(refreshed)) return true;
    if (!_hasLocalSession) return false;
    if (_lastVerifyFailure == SessionVerifyFailure.rejected) {
      // A token minted a moment ago is still refused: the session is dead.
      await _endDeadSession();
      return false;
    }
    await _enterUnverifiedSession();
    return false;
  }

  /// One Supabase refresh attempt, classified.
  Future<String?> _runSessionRefresh() async {
    try {
      final token = await requestRefreshedAccessToken();
      _refreshBackoff.reset();
      _syncAccessToken(token);
      _onSessionRefreshed();
      return token;
    } catch (error) {
      final failure = classifyRefreshError(error);
      debugPrint('Session refresh failed (${failure.name}): $error');
      if (failure == SessionRefreshFailure.sessionDead) {
        // Not awaited: sign-out makes API calls that may wait on this very
        // refresh, so awaiting here would deadlock.
        unawaited(_endDeadSession());
      } else {
        _refreshBackoff.recordFailure();
        unawaited(_enterUnverifiedSession());
      }
      return null;
    }
  }

  void _onSessionRefreshed() {
    if (!_isSessionUnverified) return;
    if (_rolesConfirmed) {
      _markSessionConfirmed();
      _emitStoreChange();
    } else {
      unawaited(_retryUnverifiedSession());
    }
  }

  /// Signs out exactly once for a session the auth server has ended, and
  /// leaves [AuthStore.sessionEndedNotice] for the sign-in screen.
  Future<void> _endDeadSession() {
    if (_sessionEndInProgress) {
      return _pendingSessionEnd ?? Future<void>.value();
    }
    if (!_hasLocalSession) return Future<void>.value();

    _sessionEndInProgress = true;
    _sessionEndedNotice = AuthStore.sessionEndedMessage;
    final future = _signOutDeadSession();
    _pendingSessionEnd = future;
    return future;
  }

  Future<void> _signOutDeadSession() async {
    debugPrint('Session ended by the auth server; signing out.');
    try {
      await signOut();
    } finally {
      _sessionEndInProgress = false;
      _pendingSessionEnd = null;
    }
  }

  /// Keeps the user signed in on the last known identity and schedules a
  /// re-check. Never touches roles the backend already confirmed.
  Future<void> _enterUnverifiedSession() async {
    if (!_hasLocalSession || _sessionEndInProgress) return;
    await _restoreCachedIdentity();
    if (!_hasLocalSession) return;
    _isSessionUnverified = true;
    _lastError = null;
    _scheduleSessionRetry();
    _emitStoreChange();
  }

  void _markSessionConfirmed() {
    _isSessionUnverified = false;
    _rolesConfirmed = true;
    _sessionEndedNotice = null;
    _sessionRetryTimer?.cancel();
    _sessionRetryTimer = null;
    _retryBackoff.reset();
  }

  Future<void> _restoreCachedIdentity() async {
    if (_rolesConfirmed) return;
    final cached = await SessionIdentityCache.load();
    if (cached == null || !_hasLocalSession || _rolesConfirmed) return;
    final currentUser = _userId;
    if (currentUser != null &&
        currentUser.isNotEmpty &&
        currentUser != cached.userId) {
      return;
    }

    _userId = cached.userId;
    _roles = _parseRoles(cached.roles);
    _email ??= cached.email;
    _displayName ??= cached.displayName;
    _username ??= cached.username;
    _avatarUrl ??= cached.avatarUrl;
    await _restoreActiveSpacePreference();
  }

  Future<void> _persistIdentity() async {
    final userId = _userId;
    if (!_isAuthenticated || userId == null || userId.isEmpty) return;
    await SessionIdentityCache.save(
      SessionIdentity(
        userId: userId,
        roles: List<String>.of(_roles),
        email: _email,
        displayName: _displayName,
        username: _username,
        avatarUrl: _avatarUrl,
      ),
    );
    // A sign-out that landed while saving must win.
    if (!_isAuthenticated || _userId != userId) {
      await SessionIdentityCache.clear();
    }
  }

  void _scheduleSessionRetry() {
    if (_sessionRetryTimer?.isActive ?? false) return;
    final delay = _refreshBackoff.remaining ?? _retryBackoff.nextDelay;
    _retryBackoff.recordFailure();
    _sessionRetryTimer = Timer(delay, () {
      _sessionRetryTimer = null;
      unawaited(_retryUnverifiedSession());
    });
  }

  Future<void> _retryUnverifiedSession() async {
    if (_sessionRetryInFlight) return;
    if (!_isSessionUnverified || !_hasLocalSession || _sessionEndInProgress) {
      return;
    }
    final token = _accessToken;
    if (token == null || token.isEmpty) return;

    _sessionRetryInFlight = true;
    try {
      if (await _confirmSession(token)) {
        await _hydrateProfileFromMe(forceRefresh: true);
        unawaited(_persistIdentity());
        _emitStoreChange();
      }
    } catch (error) {
      debugPrint('Session re-check failed: $error');
    } finally {
      _sessionRetryInFlight = false;
    }
  }

  void _onConnectivityRestored() {
    _refreshBackoff.reset();
    _retryBackoff.reset();
    if (!_isSessionUnverified) return;
    _sessionRetryTimer?.cancel();
    _sessionRetryTimer = null;
    unawaited(_retryUnverifiedSession());
  }

  void _resetSessionHealth() {
    _isSessionUnverified = false;
    _rolesConfirmed = false;
    _lastVerifyFailure = null;
    _sessionRetryTimer?.cancel();
    _sessionRetryTimer = null;
    _refreshBackoff.reset();
    _retryBackoff.reset();
  }
}

Stream<void>? _defaultConnectivityRestored() {
  try {
    return Connectivity()
        .onConnectivityChanged
        .where(
          (results) => results.any((r) => r != ConnectivityResult.none),
        )
        .map((_) {});
  } catch (_) {
    return null;
  }
}
