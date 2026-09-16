import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/mining/presentation/pages/earn_faster_screen.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_fixtures.dart';
import '../support/mine_harness.dart';

Map<String, dynamic> _referral({
  int active = 2,
  int total = 3,
  bool open = true,
}) =>
    {
      'code': 'BNC4K92X',
      'bindWindowOpen': open,
      'canBindUntil': iso(DateTime(2026, 9, 16, 22)),
      'activeDirectReferrals': active,
      'totalDirectReferrals': total,
    };

Map<String, dynamic> _friend(
  String name,
  int level, {
  bool active = true,
  DateTime? lastActive,
}) =>
    {
      'id': name.toLowerCase(),
      'email': '${name.toLowerCase()}@mail.test',
      'username': name.toLowerCase(),
      'displayName': name,
      'isActive': active,
      'lastActiveAt': lastActive == null ? null : iso(lastActive),
      'currentLevel': {
        'id': 'l$level',
        'slug': 'level-$level',
        'name': 'Level $level',
        'level': level,
      },
    };

Future<void> _pump(WidgetTester tester, FakeMineRepo repo) async {
  usePhone(tester);
  await tester.pumpWidget(
    mineHost(
      store: mineStore(repo, now: runningNow),
      settings: await loadedSettings(FakeNotificationsRepo()),
      child: const EarnFasterScreen(),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('11a · boost, rule, code, friend-code row, friends',
      (tester) async {
    final repo = FakeMineRepo(mineSnapshotJson())
      ..referralBody = _referral()
      ..downline = [
        _friend('Tenzin', 5),
        _friend('Mirae', 2),
        _friend(
          'Dexlin',
          1,
          active: false,
          lastActive: runningNow.subtract(const Duration(days: 12)),
        ),
      ];
    await _pump(tester, repo);

    expectTopToBottom(tester, [
      find.text('Earn faster'),
      find.text('+10%'),
      find.text(
        '+5% per active friend, max +100%. '
        'Active means mined in the last 7 days.',
      ),
      find.text('BNC4K92X'),
      find.text('Share code'),
      find.text("Have a friend's code?"),
      find.text('YOUR FRIENDS'),
      find.text('Tenzin'),
      find.text('Mirae'),
      find.text('Dexlin'),
      find.text("Dexlin's +5% counts again when they mine."),
    ]);
    expect(find.text('2 active friends · max +100%'), findsOneWidget);
    expect(find.text('Today only'), findsOneWidget);
    expect(find.text('2 OF 3 ACTIVE'), findsOneWidget);
    expect(find.text('ACTIVE'), findsNWidgets(2));
    expect(find.text('12 DAYS'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.textContaining('@mail.test'), findsNothing);
    expect(
      find.byKey(const ValueKey('mine-meter-on')),
      findsNWidgets(2),
    );
    expect(find.byKey(const ValueKey('mine-meter-off')), findsNWidgets(18));
  });

  testWidgets('the friend-code row is absent once the window closes',
      (tester) async {
    final repo = FakeMineRepo(mineSnapshotJson())
      ..referralBody = _referral(open: false)
      ..downline = [_friend('Tenzin', 5)];
    await _pump(tester, repo);

    expect(find.text('BNC4K92X'), findsOneWidget);
    expect(find.text("Have a friend's code?"), findsNothing);
    expect(find.textContaining('closed'), findsNothing);
  });

  testWidgets('11b · no friends: an invitation and today\'s rate',
      (tester) async {
    final repo = FakeMineRepo(mineSnapshotJson())
      ..referralBody = _referral(active: 0, total: 0);
    await _pump(tester, repo);

    expectTopToBottom(tester, [
      find.text('Invite a friend, earn 126 BNP a day'),
      find.text('+5% per active friend, max +100%.'),
      find.text('BNC4K92X'),
      find.text('Share code'),
      find.text("Have a friend's code?"),
      find.text('YOUR RATE NOW'),
      find.text('120 BNP'),
      find.text('No boost yet.'),
    ]);
    expect(find.text('a day · 5 BNP/hr'), findsOneWidget);
    expect(find.text('YOUR FRIENDS'), findsNothing);
    expect(find.byKey(const ValueKey('mine-meter-on')), findsNothing);
  });

  testWidgets('Copy puts the code on the clipboard', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final repo = FakeMineRepo(mineSnapshotJson())
      ..referralBody = _referral(active: 0, total: 0);
    await _pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('mine-copy-code')));
    await tester.pump();
    expect(copied, ['BNC4K92X']);
    expect(find.text('Code copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('/referral-code opens Earn faster', (tester) async {
    final builder = ProtectedRoutes.getAll()[AppRoutes.referralCode]!;
    final repo = FakeMineRepo(mineSnapshotJson())
      ..referralBody = _referral(active: 0, total: 0);
    usePhone(tester);
    await tester.pumpWidget(
      mineHost(
        store: mineStore(repo, now: runningNow),
        settings: await loadedSettings(FakeNotificationsRepo()),
        child: Builder(builder: builder),
      ),
    );
    await tester.pump();
    expect(find.byType(EarnFasterScreen), findsOneWidget);
  });
}
