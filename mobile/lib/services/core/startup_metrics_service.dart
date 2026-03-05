import 'package:flutter/foundation.dart';

class StartupMetricsService {
  static DateTime? _processStartAt;
  static DateTime? _firstFrameAt;
  static DateTime? _homeShellReadyAt;
  static DateTime? _homeFeedReadyAt;
  static DateTime? _edgeReadyAt;
  static int _apiCallsInFirst10s = 0;

  static void markProcessStart() {
    _processStartAt ??= DateTime.now();
  }

  static void markFirstFrame() {
    _firstFrameAt ??= DateTime.now();
    _log('first_frame_ms', _elapsedFromProcess(_firstFrameAt));
  }

  static void markHomeShellReady() {
    _homeShellReadyAt ??= DateTime.now();
    _log('home_shell_ready_ms', _elapsedFromProcess(_homeShellReadyAt));
  }

  static void markHomeFeedReady() {
    _homeFeedReadyAt ??= DateTime.now();
    _log('home_feed_ready_ms', _elapsedFromProcess(_homeFeedReadyAt));
  }

  static void markEdgeReady() {
    _edgeReadyAt ??= DateTime.now();
    _log('edge_brief_ready_ms', _elapsedFromProcess(_edgeReadyAt));
  }

  static void recordApiCall() {
    final startedAt = _processStartAt;
    if (startedAt == null) return;

    final secondsSinceStart = DateTime.now().difference(startedAt).inSeconds;
    if (secondsSinceStart <= 10) {
      _apiCallsInFirst10s += 1;
      if (_apiCallsInFirst10s == 1 || _apiCallsInFirst10s % 5 == 0) {
        _log('api_calls_first_10s', _apiCallsInFirst10s);
      }
    }
  }

  static int? _elapsedFromProcess(DateTime? timestamp) {
    final startedAt = _processStartAt;
    if (startedAt == null || timestamp == null) return null;
    return timestamp.difference(startedAt).inMilliseconds;
  }

  static void _log(String key, Object? value) {
    if (!kDebugMode) return;
    debugPrint('[startup-metrics] $key=$value');
  }
}
