import 'package:blocnet/features/profile/data/models/profile_search_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileSearchResult.fromApi', () {
    test('parses currentLevel when present', () {
      final result = ProfileSearchResult.fromApi({
        'id': 'user-1',
        'displayName': 'Hunter One',
        'username': 'hunter1',
        'roles': ['hunter'],
        'followersCount': 12,
        'currentLevel': {
          'id': 'lvl-9',
          'slug': 'legend',
          'name': 'Legend',
          'level': 9,
          'isActive': true,
        },
      });

      expect(result.isHunter, isTrue);
      expect(result.currentLevel?.slug, 'legend');
      expect(result.currentLevel?.level, 9);
    });

    test('tolerates a missing currentLevel', () {
      final result = ProfileSearchResult.fromApi({
        'id': 'user-2',
        'username': 'plain',
        'roles': <String>[],
      });

      expect(result.currentLevel, isNull);
    });
  });
}
