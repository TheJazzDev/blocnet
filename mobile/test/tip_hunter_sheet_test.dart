import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/data/repositories/tip_api_repository.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_copy.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _recipient = TipRecipient(
  userId: 'u-hunter',
  username: 'gemfinder',
  displayName: 'Gem Finder With A Rather Long Display Name',
  isHunterHint: true,
);

Map<String, dynamic> _currency() => {
      'code': 'BNP',
      'symbol': 'BNP',
      'decimals': 3,
      'feePolicy': {'feeBps': 100, 'minTip': '0', 'senderPaysFee': true},
    };

class _FakeTipRepo extends TipApiRepository {
  _FakeTipRepo({this.error});

  final Object? error;
  final List<Map<String, String?>> sent = [];

  @override
  Future<TipOverview?> fetchOverview() async => TipOverview.fromApi({
        'activeCurrency': _currency(),
        'balances': [
          {'currency': _currency(), 'balance': '12.5'},
        ],
      });

  @override
  Future<TipHistoryResponse?> fetchHistory({
    int limit = 30,
    int offset = 0,
    String direction = 'all',
    String? currencyCode,
  }) async =>
      TipHistoryResponse.fromApi({
        'data': [
          {
            'id': 't1',
            'direction': 'sent',
            'amount': '2',
            'currency': _currency(),
            'recipient': {'id': 'u-hunter'},
            'note': 'gm',
            'createdAt': '2026-09-17T12:04:00Z',
          },
        ],
        'total': 1,
      });

  @override
  Future<TipTransaction?> sendTip({
    required String amount,
    String? toUserId,
    String? toUsername,
    String? currencyCode,
    String? note,
    String? contextType,
    String? contextId,
    String? idempotencyKey,
  }) async {
    sent.add({
      'amount': amount,
      'toUserId': toUserId,
      'currencyCode': currencyCode,
      'idempotencyKey': idempotencyKey,
    });
    if (error != null) throw error!;
    return null;
  }
}

class _FakeProfileStore extends UserProfileStore {
  int refreshes = 0;

  @override
  Future<void> refreshAll({bool forceRefresh = true}) async => refreshes++;
}

Future<void> _pumpSheet(
  WidgetTester tester,
  TipsStore store, {
  UserProfileStore? profile,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>(
          create: (_) => AuthStore(
            enableSupabaseAuthListener: false,
            supabaseConfiguredOverride: false,
          ),
        ),
        ChangeNotifierProvider<TipsStore>.value(value: store),
        ChangeNotifierProvider<UserProfileStore>.value(
          value: profile ?? _FakeProfileStore(),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => TipHunterSheet.show(
                  context,
                  recipient: _recipient,
                  contextType: 'update',
                  contextId: 'up-1',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester, String amount) async {
  await tester.enterText(find.byKey(const ValueKey('tip-amount')), amount);
  final button = find.widgetWithText(ElevatedButton, 'Send tip');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fits a 375px phone with its controls', (tester) async {
    await _pumpSheet(tester, TipsStore(repository: _FakeTipRepo()));

    expect(tester.takeException(), isNull);
    expect(find.text('Send a tip'), findsOneWidget);
    expect(find.text(_recipient.label), findsOneWidget);
    expect(find.text('@gemfinder'), findsOneWidget);
    expect(find.text('HUNTER'), findsOneWidget);
    expect(find.text('12.5 BNP'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);
    expect(find.text('You pay'), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-note')), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Send tip'), findsOneWidget);
    expect(find.text('gm'), findsOneWidget);
    expect(find.text('2 BNP'), findsOneWidget);
  });

  testWidgets('rejects a bad amount without sending', (tester) async {
    final repo = _FakeTipRepo();
    await _pumpSheet(tester, TipsStore(repository: repo));

    await _send(tester, 'abc');
    expect(find.text('Enter a valid amount.'), findsOneWidget);

    await _send(tester, '1.0001');
    expect(find.text('Use up to 3 decimal places.'), findsOneWidget);
    expect(repo.sent, isEmpty);
  });

  testWidgets('sends once, closes and refreshes the profile', (tester) async {
    final repo = _FakeTipRepo();
    final profile = _FakeProfileStore();
    await _pumpSheet(tester, TipsStore(repository: repo), profile: profile);

    await _send(tester, '1.5');

    expect(repo.sent, hasLength(1));
    expect(repo.sent.single['amount'], '1.5');
    expect(repo.sent.single['toUserId'], 'u-hunter');
    expect(repo.sent.single['currencyCode'], 'BNP');
    expect(repo.sent.single['idempotencyKey'], startsWith('tip-'));
    expect(profile.refreshes, 1);
    expect(find.byType(TipHunterSheet), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a server fault reads as a plain sentence', (tester) async {
    final repo = _FakeTipRepo(
      error: ApiException('Request failed', statusCode: 500),
    );
    await _pumpSheet(tester, TipsStore(repository: repo));

    await _send(tester, '1');

    expect(find.text(tipFailedText), findsOneWidget);
    expect(find.textContaining('Request failed'), findsNothing);
    expect(find.byType(TipHunterSheet), findsOneWidget);
  });

  testWidgets('a refused tip keeps the backend sentence', (tester) async {
    final repo = _FakeTipRepo(
      error: ApiException(
        'Request failed',
        statusCode: 400,
        responseBody: '{"message":"Insufficient BNP balance."}',
      ),
    );
    await _pumpSheet(tester, TipsStore(repository: repo));

    await _send(tester, '1');

    expect(find.text('Insufficient BNP balance.'), findsOneWidget);
  });

  test('fee and minimum labels', () {
    TipCurrencyFeePolicy policy(int bps, String min, bool senderPays) =>
        TipCurrencyFeePolicy.fromApi({
          'feeBps': bps,
          'minTip': min,
          'senderPaysFee': senderPays,
        });
    expect(tipFeeLabel(policy(150, '0', true)), '1.5%');
    expect(tipFeeLabel(policy(125, '0', true)), '1.25%');
    expect(tipFeeLabel(null), '0%');
    expect(tipMinimumLabel(policy(0, '0', true), 'BNP'), isNull);
    expect(tipMinimumLabel(policy(0, '0.5', true), 'BNP'), 'Min 0.5 BNP');
    expect(tipFeePayer(policy(0, '0', false)), 'Recipient pays');
  });
}
