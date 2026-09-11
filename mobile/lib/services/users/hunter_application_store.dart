import 'package:blocnet/features/hunter/data/repositories/hunter_applications_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the current user's Become-a-Hunter application.
///
/// The backend has no "my application" read endpoint, so the pending
/// state is remembered per user in SharedPreferences once a submission
/// succeeds (or the backend reports one is already pending), and cleared
/// as soon as the account gains the hunter role.
class HunterApplicationStore extends ChangeNotifier {
  HunterApplicationStore({HunterApplicationsApiRepository? repository})
      : _repository = repository ?? HunterApplicationsApiRepository();

  final HunterApplicationsApiRepository _repository;

  String? _userId;
  bool _isPending = false;
  bool _isSubmitting = false;
  bool _hasLoaded = false;
  String? _lastError;

  bool get isPending => _isPending;
  bool get isSubmitting => _isSubmitting;
  bool get hasLoaded => _hasLoaded;
  String? get lastError => _lastError;

  static String pendingKeyFor(String userId) =>
      'blocnet_hunter_application_pending_$userId';

  /// Re-scopes the store to [userId]. When the account already holds the
  /// hunter role any remembered pending flag is stale and is dropped.
  Future<void> ensureUserScope(String? userId, {required bool isHunter}) async {
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      if (_userId != null || _isPending) {
        _userId = null;
        _isPending = false;
        _hasLoaded = false;
        notifyListeners();
      }
      return;
    }

    if (_userId != normalized) {
      _userId = normalized;
      _hasLoaded = false;
      _isPending = false;
      final prefs = await SharedPreferences.getInstance();
      if (_userId != normalized) return;
      _isPending = prefs.getBool(pendingKeyFor(normalized)) == true;
      _hasLoaded = true;
      notifyListeners();
    }

    if (isHunter && _isPending) {
      await _setPending(false);
    }
  }

  /// Submits the application. Returns true when the application is now
  /// pending (freshly created or already on file).
  Future<bool> submit(String reason) async {
    final userId = _userId;
    final trimmed = reason.trim();
    if (_isSubmitting || userId == null || trimmed.isEmpty) return false;

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      await _repository.applyForHunter(reason: trimmed);
      await _setPending(true);
      return true;
    } catch (error) {
      if (error is ApiException && _isAlreadyPending(error)) {
        await _setPending(true);
        return true;
      }
      _lastError = describeApiError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool _isAlreadyPending(ApiException error) {
    if (error.statusCode != 400) return false;
    return describeApiError(error).toLowerCase().contains('pending');
  }

  Future<void> _setPending(bool value) async {
    final userId = _userId;
    _isPending = value;
    notifyListeners();
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(pendingKeyFor(userId), true);
    } else {
      await prefs.remove(pendingKeyFor(userId));
    }
  }
}
