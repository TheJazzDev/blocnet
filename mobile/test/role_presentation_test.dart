import 'package:blocnet/shared/utils/role_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('role presentation', () {
    test('prioritizes core team over community admin', () {
      expect(
        resolvePrimaryRoleLabelFromRoles(['core_team', 'community_admin']),
        'CORE TEAM',
      );
    });

    test('prioritizes community admin over community moderator', () {
      expect(
        resolvePrimaryRoleLabelFromRoles(
          ['community_admin', 'community_moderator'],
        ),
        'ADMIN',
      );
    });

    test('uses moderator when no higher community role exists', () {
      expect(
        resolvePrimaryRoleLabelFromRoles(['community_moderator', 'hunter']),
        'MODERATOR',
      );
    });

    test('falls back to hunter when no community role exists', () {
      expect(resolvePrimaryRoleLabelFromRoles(['hunter']), 'HUNTER');
    });
  });
}
