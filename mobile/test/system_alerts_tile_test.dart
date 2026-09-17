import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/features/system_alerts/presentation/utils/system_alert_format.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_details_sheet.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_tile.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 17, 12);

SystemAlertModel _alert({String status = 'error'}) => SystemAlertModel(
      id: 'alert-1',
      action: 'wallet_withdrawal_broadcast_failed_with_a_long_action_name',
      source: 'wallet',
      provider: 'turnkey',
      status: status,
      resourceType: 'wallet_withdrawal',
      resourceId: 'wd-123',
      summary: 'Withdrawal broadcast failed after several retries on the '
          'BSC node while the member waited',
      metadata: const {'attempts': 3, 'reason': 'nonce too low'},
      createdAt: _now.subtract(const Duration(minutes: 5)),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a long alert fits 375px and shows an outlined status pill',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          SystemAlertTile(alert: _alert(), onTap: () {}, now: _now),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('ERROR'), findsOneWidget);
    expect(find.text('11:55'), findsOneWidget);
  });

  testWidgets('the details sheet fits 375px and lists the fields',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showSystemAlertDetails(context, _alert()),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Alert details'), findsOneWidget);
    expect(find.text('RESOURCE ID'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open in admin console'),
      200,
      scrollable: find
          .ancestor(
            of: find.text('Alert details'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Open in admin console'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('status colours come from the palette', () {
    expect(alertStatusColor('error'), AppColors.tagWarning);
    expect(alertStatusColor('warning'), AppColors.warning500);
    expect(alertStatusColor('success'), AppColors.successColor);
  });

  test('load errors never show the backend text', () {
    expect(
      systemAlertsErrorText(ApiException('Internal server error: boom',
          statusCode: 500)),
      systemAlertsLoadErrorText,
    );
    expect(
      systemAlertsErrorText(ApiException('Invalid or expired token')),
      systemAlertsSessionErrorText,
    );
    expect(systemAlertsErrorText(StateError('x')), systemAlertsLoadErrorText);
  });
}
