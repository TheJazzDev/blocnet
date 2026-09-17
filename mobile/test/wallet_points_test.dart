import 'package:blocnet/features/profile/data/models/profile_search_result_model.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/data/repositories/wallet_api_repository.dart';
import 'package:blocnet/features/wallet/presentation/pages/points_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/pages/send_points_page.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/points_transfer_form.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/asset_row.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _bnpJson = <String, dynamic>{
  'asset': 'BNP',
  'symbol': 'BNP',
  'name': 'Blocnet Points',
  'network': 'blocnet',
  'assetKind': 'points',
  'available': '12.345',
  'pending': '0',
  'locked': '0',
  'usdPrice': '0',
  'usdValue': '0',
  'priceSource': 'none',
  'decimals': 3,
  'balanceAtomic': '12345',
  'canSend': true,
  'canReceive': true,
};

Map<String, dynamic> _summary({required String status}) => {
      'wallet': {'status': status, 'address': null},
      'assets': [
        _bnpJson,
        {
          'asset': 'BNT',
          'symbol': 'BNT',
          'name': 'Blocnet',
          'assetKind': 'erc20',
          'available': '0',
          'priceSource': 'fallback',
        },
      ],
      'features': {
        'supportedAssets': ['BNT'],
        'transferEnabledAssets': ['BNT'],
      },
    };

class _FakeWalletRepository extends WalletApiRepository {
  // On-chain wallet is off in every case: BNP must work regardless.
  _FakeWalletRepository({this.error});

  final Object? error;
  final List<Map<String, String?>> sent = [];

  @override
  Future<WalletSnapshot?> fetchWalletSummary() async =>
      WalletSnapshot.fromApi(_summary(status: 'disabled'));

  @override
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
    String? asset,
  }) async =>
      const [];

  @override
  Future<List<WalletWithdrawalRequest>> fetchWithdrawals({
    int limit = 50,
    int offset = 0,
    String? status,
    String? asset,
  }) async {
    if (asset == walletPointsAsset) {
      throw StateError('BNP has no withdrawals');
    }
    return const [];
  }

  @override
  Future<String?> sendPoints({
    required String recipient,
    required String amountAtomic,
    required String idempotencyKey,
    String? note,
  }) async {
    sent.add({
      'recipient': recipient,
      'amountAtomic': amountAtomic,
      'idempotencyKey': idempotencyKey,
      'note': note,
    });
    if (error != null) throw error!;
    return 'tx-1';
  }
}

Future<WalletStore> _loadedStore(_FakeWalletRepository repo) async {
  final store = WalletStore(repository: repo);
  await store.loadWalletSummary(force: true);
  return store;
}

Widget _app(WalletStore store, Widget home, {AuthStore? auth}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WalletStore>.value(value: store),
      ChangeNotifierProvider<WalletVisibilityStore>(
        create: (_) => WalletVisibilityStore(),
      ),
      if (auth != null) ChangeNotifierProvider<AuthStore>.value(value: auth),
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> _tapSend(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Send BNP');
  await tester.ensureVisible(button);
  await tester.tap(button);
}

void main() {
  group('BNP asset parsing', () {
    test('reads the off-chain points fields', () {
      final snapshot = WalletSnapshot.fromApi(_summary(status: 'disabled'));
      final bnp = snapshot.findAsset('bnp')!;

      expect(snapshot.walletStatus, 'disabled');
      expect(bnp.isPoints, isTrue);
      expect(bnp.isErc20, isFalse);
      expect(bnp.decimals, 3);
      expect(bnp.canSend, isTrue);
      expect(bnp.canReceive, isTrue);
      expect(assetBadgeText(bnp), 'In-app');
      expect(formatAssetAmount(bnp), '12.345');
      expect(assetBadgeText(snapshot.findAsset('BNT')!), 'BEP-20');
    });

    test('points flags default to off when the backend omits them', () {
      final bnp = WalletAssetBalance.fromApi({
        ..._bnpJson,
        'canSend': null,
        'canReceive': null,
        'decimals': null,
      });
      expect(bnp.canSend, isFalse);
      expect(bnp.canReceive, isFalse);
      expect(bnp.decimals, isNull);
    });

    test('BNP ledger rows are points rows labelled by the backend', () {
      final tx = WalletTransaction.fromApi({
        'id': 'tt-1',
        'asset': 'BNP',
        'direction': 'outgoing',
        'reason': 'bnp_transfer',
        'amount': '2.5',
        'feeAmount': '0',
        'metadata': {'source': 'bnp_ledger', 'label': 'BNP transfer'},
        'counterparty': {'userId': 'u2', 'username': 'bob'},
        'createdAt': '2026-09-16T10:00:00.000Z',
      });
      expect(tx.isPoints, isTrue);
      expect(tx.label, 'BNP transfer');
      expect(tx.counterparty?.username, 'bob');

      final onchain = WalletTransaction.fromApi({
        'id': 'le-1',
        'asset': 'BNT',
        'reason': 'deposit_credit',
      });
      expect(onchain.isPoints, isFalse);
      expect(onchain.label, 'DEPOSIT CREDIT');
    });
  });

  group('BNP send form', () {
    test('converts decimal BNP to atomic units', () {
      expect(pointsAmountToAtomic('1.5'), '1500');
      expect(pointsAmountToAtomic(' 12 '), '12000');
      expect(pointsAmountToAtomic('0.001'), '1');
      expect(pointsAmountToAtomic('0'), isNull);
      expect(pointsAmountToAtomic('1.2345'), isNull);
      expect(pointsAmountToAtomic('-1'), isNull);
      expect(pointsAmountToAtomic('abc'), isNull);
    });

    test('normalises the @username', () {
      expect(normalizePointsRecipient(' @Bob_1 '), 'bob_1');
      expect(normalizePointsRecipient('bob'), 'bob');
      expect(normalizePointsRecipient('bob smith'), isNull);
      expect(normalizePointsRecipient('ab'), isNull);
    });

    String? validate(String recipient, String amount) => validatePointsTransfer(
          recipient: recipient,
          amount: amount,
          available: '12.345',
          ownUsername: 'alice',
        );

    test('validates recipient, self-send, amount and balance', () {
      expect(validate('', '1'), contains('@username'));
      expect(validate('not valid!', '1'), contains('valid @username'));
      expect(validate('@Alice', '1'), 'You cannot send BNP to yourself.');
      expect(validate('@bob', '0'), contains('greater than zero'));
      expect(validate('@bob', '1.0001'), contains('up to 3 decimals'));
      expect(validate('@bob', '12.346'), contains('more than your BNP'));
      expect(validate('@bob', '12.345'), isNull);
    });
  });

  group('SendPointsPage', () {
    testWidgets('has no Internal/External toggle and sends by @username',
        (tester) async {
      final repo = _FakeWalletRepository();
      final store = await _loadedStore(repo);
      final bnp = store.findAsset('BNP')!;

      await tester.pumpWidget(_app(
        store,
        SendPointsPage(asset: bnp, search: (_) async => const []),
      ));

      expect(find.text('Internal'), findsNothing);
      expect(find.text('External'), findsNothing);
      expect(find.text('Available: 12.345 BNP'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('points-recipient')), '@Bob');
      await tester.enterText(
          find.byKey(const ValueKey('points-amount')), '1.5');
      await tester.enterText(
          find.byKey(const ValueKey('points-note')), 'lunch');
      await _tapSend(tester);
      await tester.pumpAndSettle();

      expect(repo.sent, hasLength(1));
      expect(repo.sent.single['recipient'], 'bob');
      expect(repo.sent.single['amountAtomic'], '1500');
      expect(repo.sent.single['note'], 'lunch');
      expect(repo.sent.single['idempotencyKey'], startsWith('bnp-'));
    });

    testWidgets('shows validation errors without calling the backend',
        (tester) async {
      final repo = _FakeWalletRepository();
      final store = await _loadedStore(repo);

      await tester.pumpWidget(_app(
        store,
        SendPointsPage(
          asset: store.findAsset('BNP')!,
          search: (_) async => const [],
        ),
      ));

      await tester.enterText(
          find.byKey(const ValueKey('points-recipient')), 'bob');
      await tester.enterText(find.byKey(const ValueKey('points-amount')), '99');
      await _tapSend(tester);
      await tester.pump();

      expect(
          find.text('Amount is more than your BNP balance.'), findsOneWidget);
      expect(repo.sent, isEmpty);
    });

    testWidgets('shows the backend message when the send fails',
        (tester) async {
      final repo = _FakeWalletRepository(
        error: ApiException(
          'Request failed',
          statusCode: 403,
          responseBody: '{"message":"You cannot send BNP to this member"}',
        ),
      );
      final store = await _loadedStore(repo);

      await tester.pumpWidget(_app(
        store,
        SendPointsPage(
          asset: store.findAsset('BNP')!,
          search: (_) async => const [],
        ),
      ));

      await tester.enterText(
          find.byKey(const ValueKey('points-recipient')), 'bob');
      await tester.enterText(find.byKey(const ValueKey('points-amount')), '1');
      await _tapSend(tester);
      await tester.pumpAndSettle();

      expect(find.text('You cannot send BNP to this member'), findsOneWidget);
    });

    testWidgets('suggests members and fills the picked @username',
        (tester) async {
      final store = await _loadedStore(_FakeWalletRepository());

      await tester.pumpWidget(_app(
        store,
        SendPointsPage(
          asset: store.findAsset('BNP')!,
          search: (query) async => [
            const ProfileSearchResult(
              id: 'u2',
              displayName: 'Bob Builder',
              username: 'bob',
              avatarUrl: null,
              followersCount: 0,
              roles: ['user'],
            ),
          ],
        ),
      ));

      await tester.enterText(
          find.byKey(const ValueKey('points-recipient')), 'bo');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Bob Builder'), findsOneWidget);
      await tester.tap(find.text('Bob Builder'));
      await tester.pump();

      expect(find.text('@bob'), findsOneWidget);
      expect(find.text('Bob Builder'), findsNothing);
    });
  });

  group('BNP in the wallet while on-chain is disabled', () {
    testWidgets('Send from the BNP detail opens the BNP form', (tester) async {
      final store = await _loadedStore(_FakeWalletRepository());

      await tester.pumpWidget(_app(
        store,
        const Scaffold(body: ActionRow(assetCode: 'BNP')),
      ));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.byType(SendPointsPage), findsOneWidget);
      expect(find.text('Wallet is currently disabled.'), findsNothing);
    });

    testWidgets('the asset row reads as in-app points, not unpriced',
        (tester) async {
      final store = await _loadedStore(_FakeWalletRepository());

      await tester.pumpWidget(_app(
        store,
        Scaffold(
          body: AssetRow(asset: store.findAsset('BNP')!),
        ),
      ));

      expect(find.text('Blocnet Points'), findsOneWidget);
      // Symbol in the avatar, code beside the badge.
      expect(find.text('BNP'), findsNWidgets(2));
      // The network pill is drawn in caps.
      expect(find.text('IN-APP'), findsOneWidget);
      expect(find.text('12.345'), findsOneWidget);
      expect(find.text('Points'), findsOneWidget);
      expect(find.text('No USD price'), findsNothing);
    });
  });

  group('Receive BNP', () {
    testWidgets('BNP Receive shares the @username, not the on-chain QR',
        (tester) async {
      final store = await _loadedStore(_FakeWalletRepository());

      await tester.pumpWidget(_app(
        store,
        const Scaffold(body: ActionRow(assetCode: 'BNP')),
        auth: AuthStore(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        ),
      ));
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      expect(find.byType(PointsReceiveScreen), findsOneWidget);
      expect(find.byType(WalletReceiveScreen), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Share your username to receive BNP'), findsOneWidget);
    });

    testWidgets('shows the handle with Copy and Share', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PointsReceiveScreen(username: 'alice')),
      );

      expect(find.text('@alice'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('asks for a username when the member has none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PointsReceiveScreen(username: null)),
      );

      expect(
        find.text('Set a username in your profile to receive BNP.'),
        findsOneWidget,
      );
      expect(find.text('Copy'), findsNothing);
    });
  });

  test('loading BNP activity never asks for withdrawals', () async {
    final store = await _loadedStore(_FakeWalletRepository());
    // The fake throws if BNP withdrawals are requested.
    await store.loadAssetActivity('BNP', force: true);
    expect(store.lastError, isNull);
  });
}
