import 'dart:async';

import 'package:blocnet/constants/preferences_keys.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/models/ui_layout_mode_contract.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedViewModeStore extends ChangeNotifier implements UiLayoutModeContract {
  FeedViewModeStore() {
    unawaited(load());
  }

  FeedViewMode _mode = FeedViewMode.list;
  bool _hasLoaded = false;

  @override
  FeedViewMode get mode => _mode;

  Future<void> load() async {
    if (_hasLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppPreferenceKeys.feedViewMode);
      _mode = FeedViewModeParsing.fromStorage(raw);
    } catch (_) {
      _mode = FeedViewMode.list;
    } finally {
      _hasLoaded = true;
      notifyListeners();
    }
  }

  @override
  Future<void> setMode(FeedViewMode nextMode) async {
    if (_mode == nextMode && _hasLoaded) return;
    _mode = nextMode;
    _hasLoaded = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppPreferenceKeys.feedViewMode, nextMode.name);
    } catch (_) {
      // Keep in-memory state even if persistence fails.
    }
  }
}
