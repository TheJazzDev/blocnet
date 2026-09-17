import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/settings/presentation/pages/settings_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSettings extends NotificationSettingsStore {
  _FakeSettings({this.prefs, this.cat});

  final NotificationPreferences? prefs;
  final NotificationPreferencesCatalog? cat;
  int refreshes = 0;
  final List<String> cadences = [];

  @override
  NotificationPreferences? get preferences => prefs;
  @override
  NotificationPreferencesCatalog? get catalog => cat;
  @override
  bool get isLoading => false;
  @override
  String? get lastError =>
      prefs == null ? 'SocketException: failed host lookup' : null;
  @override
  Future<void> fetchInitialOnce({String? userId}) async {}
  @override
  Future<void> refresh() async => refreshes++;
  @override
  Future<bool> setDigestCadence(String cadence) async {
    cadences.add(cadence);
    return true;
  }
}

NotificationPreferences _prefs({bool push = true}) => NotificationPreferences(
      masterEnabled: push,
      digestEmailEnabled: true,
      digestCadence: 'daily',
      digestHourLocal: 8,
      digestMinuteLocal: 30,
      timezone: 'UTC',
      categories: const {},
      typeOverrides: const {},
      criticalTypes: const [],
    );

const _catalog = NotificationPreferencesCatalog(
  categories: [
    NotificationPreferenceCategoryCatalog(
      key: 'mining_referrals',
      label: 'Mining & Referrals',
      types: [
        'mining_cycle_ready_to_claim',
        'referral_bound',
        'referral_bonus_credited',
      ],
    ),
    NotificationPreferenceCategoryCatalog(
      key: 'wallet',
      label: 'Wallet',
      types: ['wallet_transfer_received'],
    ),
  ],
  criticalTypes: [],
);

Future<void> _pump(WidgetTester tester, NotificationSettingsStore store) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>(
          create: (_) => AuthStore(
            enableSupabaseAuthListener: false,
            supabaseConfiguredOverride: false,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationsStore()),
        ChangeNotifierProvider(create: (_) => FeedViewModeStore()),
        ChangeNotifierProvider<NotificationSettingsStore>.value(value: store),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('a failed load still leaves privacy and display reachable',
      (tester) async {
    final store = _FakeSettings();
    await _pump(tester, store);

    expect(find.text('Could not load notification settings'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.text('Feed layout'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Deactivate account'), 200);
    expect(find.text('Blocked users'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(store.refreshes, 1);
  });

  testWidgets('loaded settings fit 375px and the cadence pills work',
      (tester) async {
    final store = _FakeSettings(prefs: _prefs(), cat: _catalog);
    await _pump(tester, store);

    expect(tester.takeException(), isNull);
    expect(find.text('Daily at 8:30 AM'), findsOneWidget);
    await tester.tap(find.text('Weekly'));
    expect(store.cadences, ['weekly']);

    await tester.tap(find.textContaining('+ 2 more', findRichText: true));
    await tester.pump();
    expect(find.text('REFERRAL BOUND'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categories say push is off when it is', (tester) async {
    await _pump(
        tester, _FakeSettings(prefs: _prefs(push: false), cat: _catalog));
    expect(find.text('PUSH OFF'), findsOneWidget);
  });
}
