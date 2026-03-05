import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef RealtimeRecoveryTask = FutureOr<void> Function();

class RealtimeCoordinator {
  RealtimeCoordinator({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Timer> _recoveryTimers = {};

  bool hasChannel(String key) => _channels.containsKey(key);

  void trackChannel(String key, RealtimeChannel channel) {
    _channels[key] = channel;
  }

  void removeChannel(String key) {
    final channel = _channels.remove(key);
    if (channel == null) return;
    _resolvedClient?.removeChannel(channel);
  }

  void cancelDebounce(String key) {
    _debounceTimers.remove(key)?.cancel();
  }

  void scheduleDebounce(
    String key, {
    required Duration delay,
    required VoidCallback task,
  }) {
    cancelDebounce(key);
    _debounceTimers[key] = Timer(delay, () {
      _debounceTimers.remove(key);
      task();
    });
  }

  void cancelRecovery(String key) {
    _recoveryTimers.remove(key)?.cancel();
  }

  void handleStatusWithRecovery({
    required String key,
    required RealtimeSubscribeStatus status,
    required Duration recoveryDelay,
    required VoidCallback onSubscribed,
    required RealtimeRecoveryTask onRecover,
  }) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      cancelRecovery(key);
      onSubscribed();
      return;
    }

    if (status != RealtimeSubscribeStatus.channelError &&
        status != RealtimeSubscribeStatus.timedOut &&
        status != RealtimeSubscribeStatus.closed) {
      return;
    }

    if (_recoveryTimers.containsKey(key)) return;

    _recoveryTimers[key] = Timer(recoveryDelay, () async {
      _recoveryTimers.remove(key);
      await onRecover();
    });
  }

  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    for (final timer in _recoveryTimers.values) {
      timer.cancel();
    }
    _recoveryTimers.clear();

    for (final channel in _channels.values) {
      _resolvedClient?.removeChannel(channel);
    }
    _channels.clear();
  }

  SupabaseClient? get _resolvedClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
