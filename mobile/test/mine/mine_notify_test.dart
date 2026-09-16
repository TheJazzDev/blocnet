import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_notify_row.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_harness.dart';

Future<NotificationSettingsStore> _settings({
  bool master = true,
  bool category = true,
  Map<String, bool> overrides = const {},
}) {
  return loadedSettings(
    FakeNotificationsRepo(
      masterEnabled: master,
      categoryEnabled: category,
      overrides: overrides,
    ),
  );
}

Future<void> _pumpRow(
  WidgetTester tester,
  NotificationSettingsStore settings,
) async {
  usePhone(tester, height: 400);
  await tester.pumpWidget(
    mineHost(
      store: mineStore(FakeMineRepo(null)),
      settings: settings,
      child: const Padding(padding: EdgeInsets.all(16), child: MineNotifyRow()),
    ),
  );
}

Switch _switch(WidgetTester tester) =>
    tester.widget<Switch>(find.byKey(const ValueKey('mine-notify-switch')));

void main() {
  group('NotificationSettingsStore.isTypeEnabled', () {
    test('follows master, then the override, then the category', () async {
      expect((await _settings()).isTypeEnabled(mineCycleReadyType), isTrue);
      expect(
        (await _settings(master: false)).isTypeEnabled(mineCycleReadyType),
        isFalse,
      );
      expect(
        (await _settings(category: false)).isTypeEnabled(mineCycleReadyType),
        isFalse,
      );
      expect(
        (await _settings(
          category: false,
          overrides: {mineCycleReadyType: true},
        ))
            .isTypeEnabled(mineCycleReadyType),
        isTrue,
      );
      expect(
        (await _settings(overrides: {mineCycleReadyType: false}))
            .isTypeEnabled(mineCycleReadyType),
        isFalse,
      );
    });

    test('is unknown until preferences load', () {
      final store = NotificationSettingsStore(
        repository: FakeNotificationsRepo(),
      );
      expect(store.isTypeEnabled(mineCycleReadyType), isNull);
    });
  });

  testWidgets('the switch writes a per-type override, nothing else',
      (tester) async {
    final repo = FakeNotificationsRepo();
    final settings = await loadedSettings(repo);
    await _pumpRow(tester, settings);

    expect(find.text("Notify me when it's ready"), findsOneWidget);
    expect(_switch(tester).value, isTrue);

    await tester.tap(find.byKey(const ValueKey('mine-notify-switch')));
    await tester.pump();
    await tester.pump();

    expect(repo.patches, [
      {
        'typeOverrides': [
          {'type': 'mining_cycle_ready', 'enabled': false},
        ],
      },
    ]);
    expect(settings.preferences!.typeOverrides[mineCycleReadyType], isFalse);
    expect(settings.preferences!.isCategoryEnabled('mining_referrals'), isTrue);
    expect(_switch(tester).value, isFalse);

    await tester.tap(find.byKey(const ValueKey('mine-notify-switch')));
    await tester.pump();
    await tester.pump();
    expect(repo.patches.last, {
      'typeOverrides': [
        {'type': 'mining_cycle_ready', 'enabled': true},
      ],
    });
  });

  testWidgets('with all notifications off the switch reads off and is locked',
      (tester) async {
    final repo = FakeNotificationsRepo(masterEnabled: false);
    await _pumpRow(tester, await loadedSettings(repo));

    expect(_switch(tester).value, isFalse);
    expect(_switch(tester).onChanged, isNull);
  });

  testWidgets('the row is a 44 px target', (tester) async {
    await _pumpRow(tester, await _settings());
    final row = find.ancestor(
      of: find.text("Notify me when it's ready"),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(row.first).height, greaterThanOrEqualTo(44));
  });
}
