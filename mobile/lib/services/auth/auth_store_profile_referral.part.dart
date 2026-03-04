part of 'auth_store.dart';

extension _AuthStoreProfileReferralExt on AuthStore {
  Future<void> _hydrateProfileFromMe() async {
    try {
      final response = await _apiClient.get('/me');
      if (response is! Map<String, dynamic>) return;

      _displayName = response['displayName']?.toString() ?? _displayName;
      _avatarUrl = response['avatarUrl']?.toString() ?? _avatarUrl;
      _bio = response['bio']?.toString() ?? _bio;
      _username = response['username']?.toString() ?? _username;
      _referralCode = response['referralCode']?.toString() ?? _referralCode;
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

  Future<void> _setPendingReferralCodeImpl(String? code) async {
    final normalized = _normalizeReferralCode(code);
    _pendingReferralCode = normalized;
    _emitStoreChange();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (normalized == null) {
        await prefs.remove(AuthStore._pendingReferralCodeKey);
      } else {
        await prefs.setString(AuthStore._pendingReferralCodeKey, normalized);
      }
    } catch (_) {
      // Ignore storage failures and keep in-memory state.
    }
  }

  Future<void> _restorePendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingReferralCode = _normalizeReferralCode(
        prefs.getString(AuthStore._pendingReferralCodeKey),
      );
      _emitStoreChange();
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
      await _setPendingReferralCodeImpl(null);
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
        await _setPendingReferralCodeImpl(null);
      }
    } catch (_) {
      // Keep pending value and retry on next authenticated session.
    }
  }

  Future<void> _restoreActiveSpacePreference() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('${AuthStore._spaceKeyPrefix}$userId');
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
      await prefs.setString('${AuthStore._spaceKeyPrefix}$userId', _activeSpace);
    } catch (_) {
      // Ignore persistence failure; runtime state still updates.
    }
  }
}
