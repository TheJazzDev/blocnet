import 'package:blocnet/features/hunter/data/models/hunter_application_model.dart';
import 'package:blocnet/features/hunter/data/repositories/hunter_applications_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the current user's newest Become-a-Hunter application stands.
enum HunterApplicationStatus { none, pending, approved, rejected }

/// Tracks the current user's Become-a-Hunter application.
///
/// The source of truth is `GET /admin-applications/mine?targetRole=hunter`;
/// the newest row's `status` (backend `ApplicationStatus`) drives
/// [status]. A per-user SharedPreferences flag mirrors the pending state so
/// the app still shows "pending" offline or against an older backend that
/// answers 404 for the endpoint. The flag is cleared as soon as the server
/// reports anything other than pending, or the account gains the role.
class HunterApplicationStore extends ChangeNotifier {
  HunterApplicationStore({HunterApplicationsApiRepository? repository})
      : _repository = repository ?? HunterApplicationsApiRepository();

  final HunterApplicationsApiRepository _repository;

  String? _userId;
  bool _isHunter = false;
  HunterApplicationStatus _status = HunterApplicationStatus.none;
  HunterApplicationModel? _latest;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  bool _serverUnavailable = false;
  String? _lastError;

  HunterApplicationStatus get status => _status;

  /// Newest application row from the server, when it has answered.
  HunterApplicationModel? get latest => _latest;
  bool get isPending => _status == HunterApplicationStatus.pending;
  bool get isApproved => _status == HunterApplicationStatus.approved;
  bool get isRejected => _status == HunterApplicationStatus.rejected;
  bool get isSubmitting => _isSubmitting;
  bool get isRefreshing => _isRefreshing;
  bool get hasLoaded => _hasLoaded;

  /// True when the last `/mine` call hit a 404 and the store is running on
  /// the local pending flag only.
  bool get isUsingLocalFallback => _serverUnavailable;
  String? get lastError => _lastError;

  static String pendingKeyFor(String userId) =>
      'blocnet_hunter_application_pending_$userId';

  /// Re-scopes the store to [userId]: restores the local pending flag, then
  /// asks the server for the real state. When the account already holds the
  /// hunter role any pending/approved state is stale and is dropped.
  Future<void> ensureUserScope(String? userId, {required bool isHunter}) async {
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      _clearScope();
      return;
    }

    _isHunter = isHunter;
    if (_userId != normalized) {
      _userId = normalized;
      _hasLoaded = false;
      _latest = null;
      _serverUnavailable = false;
      _status = HunterApplicationStatus.none;
      final prefs = await SharedPreferences.getInstance();
      if (_userId != normalized) return;
      _status = prefs.getBool(pendingKeyFor(normalized)) == true
          ? HunterApplicationStatus.pending
          : HunterApplicationStatus.none;
      _hasLoaded = true;
      notifyListeners();
      await refreshFromServer();
    }

    if (isHunter && (isPending || isApproved)) {
      await _setStatus(HunterApplicationStatus.none);
    }
  }

  void _clearScope() {
    if (_userId == null && _status == HunterApplicationStatus.none) return;
    _userId = null;
    _latest = null;
    _status = HunterApplicationStatus.none;
    _hasLoaded = false;
    _serverUnavailable = false;
    notifyListeners();
  }

  /// Reloads the newest application from the server. A 404 (endpoint not
  /// deployed) silently keeps the local flag; any other failure keeps the
  /// current state.
  Future<void> refreshFromServer() async {
    final userId = _userId;
    if (userId == null || _isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();
    try {
      final rows = await _repository.fetchMine();
      if (_userId != userId) return;
      _serverUnavailable = false;
      await _applyServerRows(rows);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _serverUnavailable = true;
      }
    } catch (_) {
      // Offline or transient failure: keep whatever we already show.
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _applyServerRows(List<HunterApplicationModel> rows) async {
    HunterApplicationModel? newest;
    for (final row in rows) {
      if (newest == null || row.createdAt.isAfter(newest.createdAt)) {
        newest = row;
      }
    }
    _latest = newest;

    var next = HunterApplicationStatus.none;
    if (newest != null) {
      if (newest.isPending) {
        next = HunterApplicationStatus.pending;
      } else if (newest.isApproved) {
        next = HunterApplicationStatus.approved;
      } else if (newest.isRejected) {
        next = HunterApplicationStatus.rejected;
      }
    }
    if (_isHunter) next = HunterApplicationStatus.none;
    await _setStatus(next);
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
      final created = await _repository.applyForHunter(reason: trimmed);
      if (created != null) _latest = created;
      await _setStatus(HunterApplicationStatus.pending);
      return true;
    } catch (error) {
      if (error is ApiException && _isAlreadyPending(error)) {
        await _setStatus(HunterApplicationStatus.pending);
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

  Future<void> _setStatus(HunterApplicationStatus next) async {
    final userId = _userId;
    _status = next;
    notifyListeners();
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (next == HunterApplicationStatus.pending) {
      await prefs.setBool(pendingKeyFor(userId), true);
    } else {
      await prefs.remove(pendingKeyFor(userId));
    }
  }
}
