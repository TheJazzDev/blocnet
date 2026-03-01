import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ConnectivityStore extends ChangeNotifier {
  ConnectivityStore({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;

  Future<void> _init() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _setConnectivityValue(initial);
    } catch (_) {
      // Keep default until the next stream event.
    }

    try {
      _subscription = _connectivity.onConnectivityChanged.handleError((_) {
        // Ignore plugin stream errors (for example on hot-reload without
        // full native re-registration).
      }).listen(
        _setConnectivityValue,
        onError: (_) {
          // Ignore stream errors to avoid breaking global app state.
        },
      );
    } on MissingPluginException {
      // Plugin not registered in current runtime. Keep app usable and default
      // to online until a full restart registers native plugins.
      _isOffline = false;
      notifyListeners();
    } catch (_) {
      // Any unexpected issue should not crash the app.
    }
  }

  void _setConnectivityValue(dynamic value) {
    final results = _normalizeResults(value);
    if (results == null) return;
    final nextOffline = !_hasOnlineTransport(results);
    if (_isOffline == nextOffline) return;

    _isOffline = nextOffline;
    notifyListeners();
  }

  List<ConnectivityResult>? _normalizeResults(dynamic value) {
    if (value is ConnectivityResult) {
      return [value];
    }
    if (value is List<ConnectivityResult>) {
      return value;
    }
    if (value is List) {
      final results = value.whereType<ConnectivityResult>().toList();
      if (results.isNotEmpty) {
        return results;
      }
    }
    return null;
  }

  bool _hasOnlineTransport(List<ConnectivityResult> results) {
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
