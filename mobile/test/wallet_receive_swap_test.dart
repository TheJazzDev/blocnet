import 'package:blocnet/features/wallet/presentation/pages/swap_flow_screen.dart';
import 'package:blocnet/features/wallet/presentation/widgets/receive_address_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _address = '0x1234567890abcdef1234567890abcdef12345678';

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

  testWidgets('SwapFlowScreen is a single not-available state with no rows',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SwapFlowScreen()));

    expect(find.text("Swap isn't available yet"), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });
}
