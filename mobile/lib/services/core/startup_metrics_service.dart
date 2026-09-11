import 'package:flutter/foundation.dart';

class StartupMetricsService {
  static DateTime? _processStartAt;
  static DateTime? _firstFrameAt;
  static DateTime? _homeShellReadyAt;
  static DateTime? _homeFeedReadyAt;
  static DateTime? _edgeReadyAt;
  static int _apiCallsInFirst10s = 0;
  static int _apiCallsInFirst30s = 0;

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

  /// [source] is `cache` or `network`; only the first call logs, so the
  /// value tells you what the user actually saw first.
  static void markHomeFeedReady({String? source}) {
    if (_homeFeedReadyAt != null) return;
    _homeFeedReadyAt = DateTime.now();
    _log('home_feed_ready_ms', _elapsedFromProcess(_homeFeedReadyAt));
    if (source != null) _log('home_feed_source', source);
  }

  static void markEdgeReady({String? source}) {
    if (_edgeReadyAt != null) return;
    _edgeReadyAt = DateTime.now();
    _log('edge_brief_ready_ms', _elapsedFromProcess(_edgeReadyAt));
    if (source != null) _log('edge_brief_source', source);
  }

  /// Counts requests in the first 10 s after process start. Every call in
  /// the first 30 s is also logged with its path and offset so duplicate
  /// fetches are visible in the run log.
  static void recordApiCall({String? label}) {
    final startedAt = _processStartAt;
    if (startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed.inSeconds <= 30) {
      _apiCallsInFirst30s += 1;
      _log(
        'api_call',
        '#$_apiCallsInFirst30s t=${elapsed.inMilliseconds}ms ${label ?? ''}',
      );
    }
    if (elapsed.inSeconds <= 10) {
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
