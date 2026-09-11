import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TipTransaction parses currentLevel on sender and recipient', () {
    final tx = TipTransaction.fromApi({
      'id': 'tip-1',
      'amount': '5',
      'sender': {
        'id': 'user-1',
        'username': 'sender',
        'currentLevel': {
          'id': 'lvl-2',
          'slug': 'newcomer',
          'name': 'Newcomer',
          'level': 2,
          'isActive': true,
        },
      },
      'recipient': {'id': 'user-2', 'username': 'hunter'},
      'createdAt': '2026-02-21T12:00:00.000Z',
    });

    expect(tx.sender.currentLevel?.name, 'Newcomer');
    expect(tx.sender.currentLevel?.level, 2);
    expect(tx.recipient.currentLevel, isNull);
  });
}
