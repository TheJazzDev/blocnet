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
  Timer? _pollTimer;
  bool _isOffline = false;

  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;

  Future<void> _init() async {
    await _refreshConnectivity();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _refreshConnectivity(),
    );
  }

  Future<void> _refreshConnectivity() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _setConnectivityValue(initial);
    } on MissingPluginException {
      // Plugin not registered in current runtime. Keep app usable and avoid
      // repeated runtime channel exceptions.
      _pollTimer?.cancel();
      _pollTimer = null;
      if (_isOffline) {
        _isOffline = false;
        notifyListeners();
      }
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
    _pollTimer?.cancel();
    super.dispose();
  }
}
