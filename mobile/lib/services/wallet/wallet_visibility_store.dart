import 'dart:async';

import 'package:blocnet/constants/preferences_keys.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletVisibilityStore extends ChangeNotifier {
  WalletVisibilityStore() {
    unawaited(_load());
  }

  bool _isBalanceHidden = false;
  bool _hasLoaded = false;

  bool get isBalanceHidden => _isBalanceHidden;

  Future<void> _load() async {
    if (_hasLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBalanceHidden =
          prefs.getBool(AppPreferenceKeys.walletBalanceHidden) ?? false;
    } catch (_) {
      _isBalanceHidden = false;
    } finally {
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    await setHidden(!_isBalanceHidden);
  }

  Future<void> setHidden(bool hidden) async {
    if (_isBalanceHidden == hidden && _hasLoaded) return;
    _isBalanceHidden = hidden;
    _hasLoaded = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppPreferenceKeys.walletBalanceHidden, hidden);
    } catch (_) {
      // Keep in-memory state even if persistence fails.
    }
  }
}
