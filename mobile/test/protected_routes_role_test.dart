import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtectedRoutes role access', () {
    test('create update route is limited to contributor roles', () {
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.createUpdate, ['user']),
        isFalse,
      );
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.createUpdate, ['hunter']),
        isTrue,
      );
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.createUpdate, ['admin']),
        isTrue,
      );
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.createUpdate, ['owner']),
        isTrue,
      );
    });

    test('manage routes are limited to contributor roles', () {
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.manageProjects, ['user']),
        isFalse,
      );
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.manageUpdates, ['user']),
        isFalse,
      );
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.manageProjects, ['hunter']),
        isTrue,
      );
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.manageUpdates, ['hunter']),
        isTrue,
      );
    });

    test('general protected routes stay available to authenticated users', () {
      expect(ProtectedRoutes.hasRoleAccess(AppRoutes.main, ['user']), isTrue);
      expect(
        ProtectedRoutes.hasRoleAccess(AppRoutes.notifications, ['user']),
        isTrue,
      );
    });
  });
}
