import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedSyncController {
  FeedSyncController({required this.debugLabel});

  final String debugLabel;
  Timer? _pollTimer;
  RealtimeChannel? _realtimeChannel;
  bool _isSyncing = false;

  void start({
    required bool realtimeEnabled,
    required Duration pollInterval,
    required String channelName,
    required String table,
    required Future<void> Function() onSyncRequested,
  }) {
    stop();
    if (!realtimeEnabled) {
      _pollTimer = Timer.periodic(
        pollInterval,
        (_) => unawaited(_runSync(onSyncRequested)),
      );
      return;
    }

    _realtimeChannel = Supabase.instance.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (_) => unawaited(_runSync(onSyncRequested)),
        )
        .subscribe((status, [error]) {
      debugPrint('[RT][$debugLabel] status=$status error=$error');
    });
  }

  Future<void> trigger(Future<void> Function() onSyncRequested) async {
    await _runSync(onSyncRequested);
  }

  Future<void> _runSync(Future<void> Function() onSyncRequested) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await onSyncRequested();
    } finally {
      _isSyncing = false;
    }
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;

    final channel = _realtimeChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
      _realtimeChannel = null;
    }
  }

  void dispose() {
    stop();
  }
}
