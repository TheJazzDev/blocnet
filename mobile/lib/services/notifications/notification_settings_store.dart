import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/notifications/data/repositories/notifications_api_repository.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter/material.dart';

class NotificationSettingsStore extends ChangeNotifier {
  NotificationSettingsStore({NotificationsApiRepository? repository})
      : _repository = repository ?? NotificationsApiRepository();

  final NotificationsApiRepository _repository;

  NotificationPreferencesCatalog? _catalog;
  NotificationPreferences? _preferences;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _initialized = false;
  String? _boundUserId;
  String? _lastError;

  NotificationPreferencesCatalog? get catalog => _catalog;
  NotificationPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isInitialized => _initialized;
  String? get lastError => _lastError;
  bool get hasLoaded => _catalog != null && _preferences != null;

  Future<void> fetchInitialOnce({String? userId}) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      if (_boundUserId != null) {
        clear(notify: false);
      }
      return;
    }

    if (_boundUserId != normalizedUserId) {
      _boundUserId = normalizedUserId;
      _initialized = false;
      _catalog = null;
      _preferences = null;
    }

    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchPreferenceCatalog(),
        _repository.fetchPreferences(),
      ]);
      _catalog = results[0] as NotificationPreferencesCatalog;
      _preferences = results[1] as NotificationPreferences?;
      _lastError = null;
    } catch (error) {
      _lastError = describeApiError(
        error,
        fallback: 'Unable to load notification settings right now.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setMasterEnabled(bool enabled) {
    return _patchPreferences(
      patchBody: {'masterEnabled': enabled},
      optimistic: (prefs) => prefs.copyWith(masterEnabled: enabled),
    );
  }

  Future<bool> setDigestEmailEnabled(bool enabled) {
    return _patchPreferences(
      patchBody: {'digestEmailEnabled': enabled},
      optimistic: (prefs) => prefs.copyWith(digestEmailEnabled: enabled),
    );
  }

  Future<bool> setDigestCadence(String cadence) {
    return _patchPreferences(
      patchBody: {'digestCadence': cadence},
      optimistic: (prefs) => prefs.copyWith(digestCadence: cadence),
    );
  }

  Future<bool> setCategoryEnabled(String categoryKey, bool enabled) {
    return _patchPreferences(
      patchBody: {
        'categories': [
          {'category': categoryKey, 'enabled': enabled},
        ],
      },
      optimistic: (prefs) {
        final nextCategories = Map<String, bool>.from(prefs.categories);
        nextCategories[categoryKey] = enabled;
        return prefs.copyWith(categories: nextCategories);
      },
    );
  }

  void clear({bool notify = true}) {
    _catalog = null;
    _preferences = null;
    _isLoading = false;
    _isSaving = false;
    _initialized = false;
    _boundUserId = null;
    _lastError = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> _patchPreferences({
    required Map<String, dynamic> patchBody,
    required NotificationPreferences Function(NotificationPreferences current)
        optimistic,
  }) async {
    final current = _preferences;
    if (_isSaving || current == null) return false;

    _isSaving = true;
    _lastError = null;
    final snapshot = current;
    _preferences = optimistic(snapshot);
    notifyListeners();

    try {
      final updated = await _repository.updatePreferences(body: patchBody);
      if (updated != null) {
        _preferences = updated;
      } else {
        _preferences = snapshot;
      }
      _lastError = null;
      return true;
    } catch (error) {
      _preferences = snapshot;
      _lastError = describeApiError(
        error,
        fallback: 'Unable to save notification settings right now.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
