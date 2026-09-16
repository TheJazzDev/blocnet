import 'package:blocnet/features/wallet/presentation/pages/wallet_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/quick_actions.dart';
import 'package:blocnet/features/wallet/presentation/widgets/receive_address_card.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _address = '0x1234567890abcdef1234567890abcdef12345678';

Widget _withWallet(Widget child) {
  return ChangeNotifierProvider<WalletStore>(
    create: (_) => WalletStore(),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('ReceiveAddressCard shows a QR code, the address and actions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReceiveAddressCard(
              address: _address,
              networkLabel: 'BNB Smart Chain (BSC)',
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(_address), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('wallet quick actions are Receive and Send, with no Swap',
      (tester) async {
    await tester.pumpWidget(_withWallet(const QuickActions()));

    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Swap'), findsNothing);
  });

  testWidgets('the Receive quick action opens the Receive screen',
      (tester) async {
    await tester.pumpWidget(_withWallet(const QuickActions()));

    await tester.tap(find.text('Receive'));
    await tester.pumpAndSettle();

    expect(find.byType(WalletReceiveScreen), findsOneWidget);
  });

  testWidgets('asset detail Receive opens the same Receive screen',
      (tester) async {
    await tester.pumpWidget(_withWallet(const ActionRow(assetCode: 'USDT')));

    await tester.tap(find.text('Receive'));
    await tester.pumpAndSettle();

    expect(find.byType(WalletReceiveScreen), findsOneWidget);
  });
}
