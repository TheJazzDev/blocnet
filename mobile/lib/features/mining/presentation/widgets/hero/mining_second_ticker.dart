import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Whether the Mine tab holding [context] is on screen.
///
/// The main shell's `LazyTabStack` turns tickers off for hidden tabs, and
/// `TickerMode` also covers a route pushed over the shell. A bare
/// `IndexedStack` (`Visibility.maintain`) leaves hidden tabs' tickers
/// *enabled*, so the nearest `Visibility` ancestor is checked as well.
bool isMiningTabVisible(BuildContext context) {
  if (!TickerMode.getNotifier(context).value) return false;
  final visibility = context.findAncestorWidgetOfExactType<Visibility>();
  return visibility?.visible ?? true;
}

/// A one-second clock for the Mine hero (F-55).
///
/// The timer only exists while [shouldTick] is true, the app is in the
/// foreground and tickers are enabled. While the tab is hidden behind another
/// tab the timer keeps a cheap heartbeat but does no work: no rebuild, no
/// animation. Nothing in the shell tells a tab it was hidden, so the heartbeat
/// is how the hero notices it is back.
mixin MiningSecondTicker<T extends StatefulWidget> on State<T> {
  Timer? _secondTimer;
  ValueListenable<bool>? _tickerMode;
  AppLifecycleListener? _lifecycle;
  bool _appInForeground = true;
  bool _lastVisible = true;

  /// Whether the hero needs a clock at all, e.g. a cycle is live.
  bool get shouldTick;

  /// Called once a second while the tab is on screen.
  void onSecond();

  /// Called when the tab goes on or off screen while the clock runs.
  void onTabVisibilityChanged(bool visible) {}

  bool get isTickerRunning => _secondTimer != null;

  @override
  void initState() {
    super.initState();
    _appInForeground = _isForeground(WidgetsBinding.instance.lifecycleState);
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = TickerMode.getNotifier(context);
    if (!identical(notifier, _tickerMode)) {
      _tickerMode?.removeListener(syncSecondTicker);
      _tickerMode = notifier..addListener(syncSecondTicker);
    }
    syncSecondTicker();
  }

  /// Starts or stops the clock to match the current conditions. Call it when
  /// [shouldTick] may have changed.
  void syncSecondTicker() {
    final run = mounted &&
        shouldTick &&
        _appInForeground &&
        (_tickerMode?.value ?? true);
    if (run) {
      _secondTimer ??= Timer.periodic(const Duration(seconds: 1), _onTimer);
    } else {
      _secondTimer?.cancel();
      _secondTimer = null;
    }
  }

  void _onTimer(Timer _) {
    if (!mounted) return;
    final visible = isMiningTabVisible(context);
    if (visible != _lastVisible) {
      _lastVisible = visible;
      onTabVisibilityChanged(visible);
    }
    if (visible) onSecond();
  }

  void _onLifecycleChange(AppLifecycleState state) {
    final foreground = _isForeground(state);
    if (foreground == _appInForeground) return;
    _appInForeground = foreground;
    syncSecondTicker();
  }

  static bool _isForeground(AppLifecycleState? state) {
    return state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  @override
  void dispose() {
    _secondTimer?.cancel();
    _tickerMode?.removeListener(syncSecondTicker);
    _lifecycle?.dispose();
    super.dispose();
  }
}
