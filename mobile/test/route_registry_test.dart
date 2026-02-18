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
    expect(routes.containsKey(AppRoutes.notifications), isTrue);
    expect(routes.containsKey(AppRoutes.createUpdate), isTrue);
    expect(routes.containsKey(AppRoutes.submitProject), isTrue);
    expect(routes.containsKey(AppRoutes.manageProjects), isTrue);
    expect(routes.containsKey(AppRoutes.manageUpdates), isTrue);
    expect(routes.containsKey(AppRoutes.hunterHub), isTrue);
    expect(routes.containsKey(AppRoutes.becomeHunter), isTrue);
    expect(routes.containsKey(AppRoutes.home), isTrue);
    expect(routes.containsKey(AppRoutes.discover), isTrue);
    expect(routes.containsKey(AppRoutes.trending), isTrue);
    expect(routes.containsKey(AppRoutes.midPriority), isTrue);
    expect(routes.containsKey(AppRoutes.lowPriority), isTrue);
    expect(routes.containsKey(AppRoutes.highPriority), isTrue);
    expect(routes.containsKey(AppRoutes.communityCreatePost), isTrue);
    expect(routes.containsKey(AppRoutes.communityDiscussion), isTrue);
  });
}
