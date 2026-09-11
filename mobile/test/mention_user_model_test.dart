import 'package:blocnet/features/mentions/data/models/mention_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MentionUserModel.fromJson', () {
    test('parses currentLevel when present', () {
      final user = MentionUserModel.fromJson({
        'id': 'user-1',
        'username': 'satoshi',
        'displayName': 'Satoshi',
        'avatarUrl': null,
        'currentLevel': {
          'id': 'lvl-5',
          'slug': 'builder',
          'name': 'Builder',
          'level': 5,
          'color': '#22C55E',
          'isActive': true,
        },
      });

      expect(user.username, 'satoshi');
      expect(user.currentLevel, isNotNull);
      expect(user.currentLevel!.id, 'lvl-5');
      expect(user.currentLevel!.name, 'Builder');
      expect(user.currentLevel!.level, 5);
    });

    test('leaves currentLevel null when absent or malformed', () {
      final absent = MentionUserModel.fromJson({
        'id': 'user-2',
        'username': 'alice',
      });
      final malformed = MentionUserModel.fromJson({
        'id': 'user-3',
        'username': 'bob',
        'currentLevel': 'oops',
      });

      expect(absent.currentLevel, isNull);
      expect(malformed.currentLevel, isNull);
    });
  });
}
