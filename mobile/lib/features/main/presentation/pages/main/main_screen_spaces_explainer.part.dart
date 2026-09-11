part of '../main_screen.dart';

/// One-time "You have two spaces…" explainer, shown once per user the
/// first time they open the app with more than one available space.
extension _MainScreenSpacesExplainer on _MainScreenState {
  Future<void> _maybePromptSpacesExplainer() async {
    if (!mounted || _isShowingSpacesExplainer) return;

    final auth = context.read<AuthStore>();
    final userId = auth.userId?.trim();
    if (!auth.isAuthenticated ||
        auth.isBootstrapping ||
        userId == null ||
        userId.isEmpty) {
      return;
    }
    if (_checkedSpacesExplainerUserId == userId) return;

    // Roles may still be loading; only settle the check once the user
    // actually has a second space to explain.
    final spaces = SpaceMeta.availableFor(auth);
    if (spaces.length <= 1) return;
    _checkedSpacesExplainerUserId = userId;

    final prefs = await SharedPreferences.getInstance();
    final key = SpacesExplainerSheet.seenKeyFor(userId);
    if (prefs.getBool(key) == true) return;
    // Reserve before showing so a re-entrant check cannot stack a second
    // sheet on top of this one.
    await prefs.setBool(key, true);
    if (!mounted) return;

    _isShowingSpacesExplainer = true;
    try {
      await SpacesExplainerSheet.show(context, spaces: spaces);
    } finally {
      _isShowingSpacesExplainer = false;
    }
  }
}
