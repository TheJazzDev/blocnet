import 'dart:async';
import 'dart:io';

import 'package:blocnet/app/config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ConnectivityStore extends ChangeNotifier {
  ConnectivityStore({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<dynamic>? _connectivitySubscription;
  Timer? _pollTimer;
  bool _isOffline = false;
  bool _hasEvaluated = false;

  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;
  bool get hasEvaluated => _hasEvaluated;

  Future<void> _init() async {
    await _refreshConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (value) {
        unawaited(_setConnectivityValue(value));
      },
      onError: (_) {
        // Ignore transient stream errors.
      },
    );
    _pollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(_refreshConnectivity()),
    );
  }

  Future<void> _refreshConnectivity() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      await _setConnectivityValue(initial);
    } on MissingPluginException {
      // Plugin not registered in current runtime. Keep app usable and avoid
      // repeated runtime channel exceptions.
      _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
      _pollTimer?.cancel();
      _pollTimer = null;
      if (_isOffline || !_hasEvaluated) {
        _isOffline = false;
        _hasEvaluated = true;
        notifyListeners();
      }
    } catch (_) {
      // Any unexpected issue should not crash the app.
    }
  }

  Future<void> _setConnectivityValue(dynamic value) async {
    final results = _normalizeResults(value);
    if (results == null) return;
    final nextOffline = await _computeOffline(results);
    final shouldNotify = !_hasEvaluated || _isOffline != nextOffline;
    _hasEvaluated = true;
    if (!shouldNotify) return;

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

  Future<bool> _computeOffline(List<ConnectivityResult> results) async {
    if (!_hasOnlineTransport(results)) {
      return true;
    }

    final hostCandidates = <String>[
      Uri.tryParse(AppConfig.apiBaseUrl)?.host ?? '',
      'one.one.one.one',
    ].where((host) => host.trim().isNotEmpty).toSet();

    for (final host in hostCandidates) {
      try {
        final resolved = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 2));
        if (resolved.any((address) => address.rawAddress.isNotEmpty)) {
          return false;
        }
      } catch (_) {
        // Try next host candidate.
      }
    }

    return true;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
