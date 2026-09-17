import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_category_filter_bar.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:blocnet/features/notifications/presentation/widgets/parts/notif_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 17, 12);

NotificationModel _item({bool isRead = false, String? type}) =>
    NotificationModel(
      id: 'n1',
      type: type ?? 'wallet_transfer_received',
      title: 'A very long notification title that keeps going well past '
          'the width of a small phone screen without stopping',
      body: 'A long body. ' * 30,
      isRead: isRead,
      createdAt: _now.subtract(const Duration(hours: 3)),
    );

Future<void> _pumpAt375(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ListView(children: [child])),
  ));
}

void main() {
  testWidgets('a long tile fits a 375px screen', (tester) async {
    await _pumpAt375(
      tester,
      NotificationTile(item: _item(), onTap: () {}, now: _now),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('3h'), findsOneWidget);
  });

  testWidgets('unread rows show the dot on the surface; read rows do not',
      (tester) async {
    await _pumpAt375(
      tester,
      NotificationTile(item: _item(), onTap: () {}, now: _now),
    );
    expect(find.byKey(const ValueKey('notification-unread-dot')),
        findsOneWidget);

    await _pumpAt375(
      tester,
      NotificationTile(item: _item(isRead: true), onTap: () {}, now: _now),
    );
    expect(
        find.byKey(const ValueKey('notification-unread-dot')), findsNothing);
  });

  testWidgets('the category reads as an outlined caps pill', (tester) async {
    await _pumpAt375(
      tester,
      NotificationTile(item: _item(), onTap: () {}, now: _now),
    );
    final style = styleForNotificationType('wallet_transfer_received');
    final pill = tester.widget<NotifPill>(find.byType(NotifPill));
    expect(pill.label, style.label);
    expect(find.text(style.label.toUpperCase()), findsOneWidget);
  });

  testWidgets('tapping the tile calls onTap', (tester) async {
    var taps = 0;
    await _pumpAt375(
      tester,
      NotificationTile(item: _item(), onTap: () => taps++, now: _now),
    );
    await tester.tap(find.byType(NotificationTile));
    expect(taps, 1);
  });

  test('every category has its own colour', () {
    final colors = notificationCategoryFilters
        .where((f) => f.key != 'all')
        .map((f) => f.color)
        .toSet();
    expect(colors, hasLength(notificationCategoryFilters.length - 1));
  });

  test('filled button text suits the accent', () {
    expect(notifOnAccent(AppColors.hunterAccent), Colors.black);
    expect(notifOnAccent(AppColors.userAccent), Colors.white);
  });

  testWidgets('the empty state names the filter', (tester) async {
    await _pumpAt375(
      tester,
      const EmptyNotificationsState(categoryLabel: 'Wallet'),
    );
    expect(find.text('No wallet notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
