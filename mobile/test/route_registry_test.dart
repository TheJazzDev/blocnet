import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/routes.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all declared auth routes are registered', () {
    final routes = AuthRoutes.getAll();

    expect(routes.containsKey(AppRoutes.signIn), isTrue);
    expect(routes.containsKey(AppRoutes.signUp), isTrue);
    expect(routes.containsKey(AppRoutes.verifyEmail), isTrue);
    expect(routes.containsKey(AppRoutes.forgotPassword), isTrue);
    expect(routes.containsKey(AppRoutes.resetPassword), isTrue);
  });

  test('all declared protected routes are registered', () {
    final routes = ProtectedRoutes.getAll();

    expect(routes.containsKey(AppRoutes.main), isTrue);
    expect(routes.containsKey(AppRoutes.profile), isTrue);
    expect(routes.containsKey(AppRoutes.settings), isTrue);
    expect(routes.containsKey(AppRoutes.wallet), isTrue);
    expect(routes.containsKey(AppRoutes.tipsHistory), isTrue);
    expect(routes.containsKey(AppRoutes.notifications), isTrue);
    expect(routes.containsKey(AppRoutes.mining), isTrue);
    expect(routes.containsKey(AppRoutes.miningLeaderboard), isTrue);
    expect(routes.containsKey(AppRoutes.miningHourlyHistory), isTrue);
    expect(routes.containsKey(AppRoutes.createUpdate), isTrue);
    expect(routes.containsKey(AppRoutes.submitProject), isTrue);
    expect(routes.containsKey(AppRoutes.manageProjects), isTrue);
    expect(routes.containsKey(AppRoutes.manageUpdates), isTrue);
    expect(routes.containsKey(AppRoutes.hunterHub), isTrue);
    expect(routes.containsKey(AppRoutes.becomeHunter), isTrue);
    expect(routes.containsKey(AppRoutes.helpSupport), isTrue);
    expect(routes.containsKey(AppRoutes.faq), isTrue);
    expect(routes.containsKey(AppRoutes.gettingStarted), isTrue);
    expect(routes.containsKey(AppRoutes.glossary), isTrue);
    expect(routes.containsKey(AppRoutes.home), isTrue);
    expect(routes.containsKey(AppRoutes.discover), isTrue);
    expect(routes.containsKey(AppRoutes.communityCreatePost), isTrue);
    expect(routes.containsKey(AppRoutes.communityDiscussion), isTrue);
  });

  test('cut screens are no longer registered', () {
    // Trending and the three Priority screens were cut (APP_MAP section 3).
    final routes = ProtectedRoutes.getAll();
    for (final path in [
      '/trending',
      '/high-priority',
      '/mid-priority',
      '/low-priority',
    ]) {
      expect(routes.containsKey(path), isFalse, reason: path);
      expect(ProtectedRoutes.isProtectedRoute(path), isFalse, reason: path);
    }
  });
}
