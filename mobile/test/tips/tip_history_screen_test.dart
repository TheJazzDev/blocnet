import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/pages/tip_history_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTips extends TipsStore {
  _FakeTips({this.rows = const [], this.error});

  final List<TipTransaction> rows;
  final String? error;

  @override
  List<TipTransaction> get sentHistory => rows;
  @override
  int get sentHistoryTotal => rows.length;
  @override
  bool get isLoadingSentHistory => false;
  @override
  String? get lastError => error;
  @override
  Future<void> loadSentHistory({
    bool force = false,
    int limit = 50,
    int offset = 0,
    String? currencyCode,
  }) async {}
}

TipTransaction _tip(
  String id, {
  Map<String, dynamic> recipient = const {'id': 'cku7x9recipient'},
  String? contextType,
  String? note,
}) {
  return TipTransaction.fromApi({
    'id': id,
    'type': 'tip',
    'direction': 'sent',
    'currency': {'code': 'BNP', 'symbol': 'BNP', 'name': 'Blocnet Point'},
    'amount': '1250.5',
    'fee': '12.5',
    'totalDebit': '1263',
    'sender': {'id': 'me'},
    'recipient': recipient,
    'contextType': contextType,
    'contextId': 'u1',
    'note': note,
    'createdAt': '2026-09-16T10:00:00Z',
  });
}

Future<void> _pump(WidgetTester tester, TipsStore store) async {
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
        ChangeNotifierProvider<TipsStore>.value(value: store),
      ],
      child: const MaterialApp(home: TipHistoryScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('rows name the party, never a raw id, and fit 375px',
      (tester) async {
    await _pump(
      tester,
      _FakeTips(rows: [
        _tip('t1', contextType: 'update'),
        _tip(
          't2',
          recipient: {
            'id': 'h2',
            'displayName': 'A hunter with a remarkably long display name',
          },
          contextType: 'public_profile',
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hunter'), findsOneWidget);
    expect(find.textContaining('cku7x9'), findsNothing);
    expect(find.textContaining('On an update'), findsOneWidget);
    expect(find.textContaining('From a profile'), findsOneWidget);
    expect(find.textContaining('public_profile'), findsNothing);
    expect(find.text('−1263 BNP'), findsNWidgets(2));
    // Both rows open something.
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
  });

  testWidgets('a failed load offers retry without the raw error',
      (tester) async {
    await _pump(tester, _FakeTips(error: 'ApiException: 502 Bad Gateway'));

    expect(find.text('Could not load tips'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('ApiException'), findsNothing);
  });

  testWidgets('nothing sent says so', (tester) async {
    await _pump(tester, _FakeTips());
    expect(find.text('No tips sent yet'), findsOneWidget);
  });
}
