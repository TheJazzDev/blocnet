import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/data/repositories/wallet_api_repository.dart';
import 'package:blocnet/features/wallet/presentation/pages/send_token_page.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_details_sheet.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_fields.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _address = '0x1234567890abcdef1234567890abcdef12345678';

Map<String, dynamic> _summary() => {
      'wallet': {'status': 'ready', 'address': _address},
      'assets': [
        {
          'asset': 'USDT',
          'symbol': 'USDT',
          'name': 'Tether USD on a very long network name that wraps',
          'assetKind': 'erc20',
          'available': '123456789.123456',
          'usdPrice': '1',
          'usdValue': '123456789.12',
          'priceSource': 'live',
        },
        {
          'asset': 'BNP',
          'symbol': 'BNP',
          'name': 'Blocnet Points',
          'assetKind': 'points',
          'available': '98765432.123',
          'priceSource': 'none',
          'decimals': 3,
          'canSend': true,
          'canReceive': true,
        },
        {
          'asset': 'BNT',
          'symbol': 'BNT',
          'name': 'Blocnet',
          'assetKind': 'erc20',
          'available': '125',
          'priceSource': 'fallback',
        },
      ],
      'features': {
        'supportedAssets': ['BNT', 'USDT'],
        'transferEnabledAssets': ['BNT', 'USDT'],
        'withdrawalEnabledAssets': ['USDT'],
      },
    };

final _longTransfer = WalletTransaction.fromApi({
  'id': 'tx-1',
  'direction': 'outgoing',
  'reason': 'internal_transfer_with_a_very_long_reason_name',
  'amount': '-123456789.123456',
  'asset': 'USDT',
  'createdAt': '2026-09-17T12:04:00Z',
});

final _failedWithdrawal = WalletWithdrawalRequest.fromApi({
  'id': 'wd-1',
  'status': 'failed',
  'toAddress': _address,
  'amount': '25',
  'reason': 'Move to my exchange',
  'failureReason': '',
  'asset': 'USDT',
  'requestedAt': '2026-09-17T12:00:00Z',
});

class _FakeRepo extends WalletApiRepository {
  @override
  Future<WalletSnapshot?> fetchWalletSummary() async =>
      WalletSnapshot.fromApi(_summary());

  @override
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
    String? asset,
  }) async =>
      [_longTransfer];

  @override
  Future<List<WalletWithdrawalRequest>> fetchWithdrawals({
    int limit = 50,
    int offset = 0,
    String? status,
    String? asset,
  }) async =>
      [_failedWithdrawal];
}

Widget _app(WalletStore store, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WalletStore>.value(value: store),
      ChangeNotifierProvider<WalletVisibilityStore>(
        create: (_) => WalletVisibilityStore(),
      ),
      ChangeNotifierProvider<AuthStore>(
        create: (_) => AuthStore(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        ),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<WalletStore> _store() async {
  final store = WalletStore(repository: _FakeRepo());
  await store.refreshAll();
  return store;
}

void main() {
  testWidgets('the wallet tab fits a 375px phone with large balances',
      (tester) async {
    await _phone(tester);
    final store = await _store();

    await tester.pumpWidget(_app(store, const WalletScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    // BNT has no price yet: it says so, and never "Pre-launch".
    expect(find.text('Price pending'), findsOneWidget);
    expect(find.textContaining('Pre-launch'), findsNothing);
    // Withdrawal status reads in plain words, in an outlined pill.
    expect(find.widgetWithText(AppPill, 'FAILED'), findsOneWidget);
  });

  testWidgets('BNP leads the assets list', (tester) async {
    await _phone(tester);
    final store = await _store();

    await tester.pumpWidget(_app(store, const WalletScreen()));
    await tester.pumpAndSettle();

    final bnp = tester.getTopLeft(find.text('Blocnet Points')).dy;
    final usdt = tester.getTopLeft(find.textContaining('Tether USD')).dy;
    expect(bnp, lessThan(usdt));
  });

  testWidgets('a long transaction row fits 375px', (tester) async {
    await _phone(tester);
    final store = await _store();
    final rows = buildWalletActivityRows(store);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [for (final r in rows) WalletActivityRow(item: r)],
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    // Ledger reasons read in title case, not shouted.
    expect(
      find.text('Internal Transfer With A Very Long Reason Name'),
      findsOneWidget,
    );
    expect(find.text('Withdrawal'), findsOneWidget);
  });

  group('failed withdrawal', () {
    test('falls back to the plain sentence when the server gives none', () {
      final details = WalletActivityDetails.from(
        WalletActivityItem(
          id: 'w',
          icon: Icons.call_made_rounded,
          title: 'Withdrawal',
          subtitle: '',
          amountLabel: '-25 USDT',
          amountColor: Colors.white,
          occurredAt: null,
          isOutgoing: true,
          isIncoming: false,
          withdrawal: _failedWithdrawal,
        ),
        null,
      );
      final what = details.fields.firstWhere((f) => f.label == 'What happened');
      expect(what.value, withdrawalFailedFallback);
      expect(
        withdrawalFailedFallback,
        'Withdrawal failed. The amount is back in your wallet.',
      );
    });

    test("keeps the server's text when there is some", () {
      expect(
        withdrawalFailureText('Gas price spiked. The amount is back.'),
        'Gas price spiked. The amount is back.',
      );
      expect(withdrawalFailureText('  '), withdrawalFailedFallback);
      expect(withdrawalFailureText(null), withdrawalFailedFallback);
    });

    testWidgets('the detail sheet shows it at 375px', (tester) async {
      await _phone(tester);
      final store = await _store();
      final row = buildWalletActivityRows(store)
          .firstWhere((r) => r.withdrawal != null);

      await tester.pumpWidget(_app(
        store,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showWalletActivityDetails(context, row),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(withdrawalFailedFallback), findsOneWidget);
      expect(find.text('WHAT HAPPENED'), findsOneWidget);
    });
  });

  group('wallet error text', () {
    late WalletStore store;
    setUp(() => store = WalletStore(repository: _FakeRepo()));

    test('keeps a readable 4xx message from the API', () {
      final error = ApiException(
        'Request failed',
        statusCode: 400,
        responseBody: '{"message":"Amount is above your daily limit"}',
      );
      expect(walletErrorText(store, error), 'Amount is above your daily limit');
    });

    test('hides server faults and exceptions', () {
      expect(
        walletErrorText(
          store,
          ApiException(
            'Request failed',
            statusCode: 500,
            responseBody: '{"message":"PrismaClientKnownRequestError: P2002"}',
          ),
        ),
        walletGenericErrorText,
      );
      expect(
        walletErrorText(store, ApiException('Request failed', statusCode: 404)),
        walletGenericErrorText,
      );
      expect(walletErrorText(store, StateError('bad state')),
          walletGenericErrorText);
      expect(
        walletErrorText(store, ApiException('Unable to connect right now.')),
        walletOfflineText,
      );
    });
  });

  testWidgets('the token send page fits 375px and validates before sending',
      (tester) async {
    await _phone(tester);
    final store = await _store();

    await tester.pumpWidget(_app(
      store,
      const SendTokenPage(
        assetCode: 'USDT',
        canTransfer: true,
        canWithdraw: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('In Blocnet'), findsOneWidget);
    expect(find.text('On-chain'), findsOneWidget);
    expect(find.text('Available: 123,456,789.123456 USDT'), findsOneWidget);

    await tester.tap(find.text('On-chain'));
    await tester.pumpAndSettle();
    expect(find.text('Reason'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Request withdrawal'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid wallet address (0x…).'), findsOneWidget);
  });

  test('withdrawal statuses read in plain words', () {
    expect(withdrawalStatusLabel('pending_review'), 'In review');
    expect(withdrawalStatusLabel('requested'), 'In review');
    expect(withdrawalStatusLabel('broadcasting'), 'Sending');
    expect(withdrawalStatusLabel('confirmed'), 'Sent');
    expect(withdrawalStatusLabel('failed'), 'Failed');
    expect(withdrawalStatusLabel('rejected'), 'Rejected');
  });
}
