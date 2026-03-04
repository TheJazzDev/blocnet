class AppPreferenceKeys {
  AppPreferenceKeys._();

  static const String feedViewMode = 'home_updates_feed_view_mode';
  static const String walletBalanceHidden = 'wallet_balance_hidden';

  @Deprecated('Use feedViewMode')
  static const String updatesFeedViewMode = feedViewMode;
}
