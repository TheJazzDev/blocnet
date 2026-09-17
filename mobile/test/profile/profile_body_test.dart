import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/profile/domain/activity_target.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/profile_body.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_hub_link_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_tabs_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../hunter_hub/hub_fixtures.dart' as hub;
import 'profile_harness.dart';

HunterBoard _board({
  int current = 4,
  int due = 1,
  ReliabilityStanding standing = ReliabilityStanding.reliable,
}) {
  return HunterBoard(
    reliability: hub.reliability(standing: standing),
    gems: [
      for (var i = 0; i < due; i++)
        hub.gem('Due $i', state: GemState.due, ago: const Duration(days: 11)),
      for (var i = 0; i < current; i++) hub.gem('Current $i'),
    ],
  );
}

ProfileBody _body(FakeProfileAuth auth) =>
    ProfileBody(auth: auth, onSignOut: () {});

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('tabs', () {
    testWidgets('are Activity and Saved; Following is gone', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository());

      expect(ProfileTabsSection.tabs, ['Activity', 'Saved']);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Following'), findsNothing);
    });

    testWidgets('Saved opens its own list', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository());

      await tester.tap(find.text('Saved'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Bookmark updates to save them here'), findsOneWidget);
      expect(find.text('No activity yet'), findsNothing);
    });
  });

  group('follow counts', () {
    testWidgets('gems followed counts the watchlist, people are separate',
        (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      await pumpProfile(
        tester,
        _body(auth),
        auth: auth,
        users: FakeUsersRepository(
          followingCount: 7,
          watchlist: [followedGem('a'), followedGem('b')],
        ),
      );

      final gems = find.byKey(const ValueKey('profile-stat-gems'));
      expect(
          find.descendant(of: gems, matching: find.text('Gems followed')),
          findsOneWidget);
      expect(find.descendant(of: gems, matching: find.text('2')),
          findsOneWidget);
      final people = find.byKey(const ValueKey('profile-stat-people'));
      expect(find.descendant(of: people, matching: find.text('7')),
          findsOneWidget);
    });

    testWidgets('the gems count opens the Gems tab', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      final tabs = <int>[];
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository(), selectedTabs: tabs);

      await tester.tap(find.byKey(const ValueKey('profile-stat-gems')));
      await tester.pump();

      expect(tabs, [MainTabScope.discoverTab]);
    });
  });

  group('hunter reliability', () {
    testWidgets('hunters see standing and current gems once', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth(hunter: true);
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository(), board: _board());

      expect(find.byKey(const ValueKey('profile-reliability')), findsOneWidget);
      expect(find.text('RELIABLE'), findsOneWidget);
      expect(find.text('4 of 5 gems current'), findsOneWidget);
      expect(find.text('Hunter Hub'), findsOneWidget);
      // The old duplicates stay on the Hub.
      for (final gone in [
        'HUNTER STATS',
        'COMMUNITY VOICE',
        'HUNTER SIGNALS',
        'Success Rate',
        'Submit New Gem',
        'Manage My Gems',
        'Manage My Updates',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('members who are not hunters see none of it', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository(), board: _board());

      expect(find.byType(HunterHubLinkSection), findsNothing);
      expect(find.text('Hunter Hub'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('gems current'), findsNothing);
    });

    testWidgets('a hunter with no gems reads New, not a zero score',
        (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth(hunter: true);
      await pumpProfile(tester, _body(auth),
          auth: auth,
          users: FakeUsersRepository(),
          board: _board(current: 0, due: 0));

      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('No gems yet'), findsOneWidget);
      expect(find.textContaining('0 of'), findsNothing);
    });

    testWidgets('a slipping hunter says so', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth(hunter: true);
      await pumpProfile(tester, _body(auth),
          auth: auth,
          users: FakeUsersRepository(),
          board: _board(
              current: 2, due: 3, standing: ReliabilityStanding.slipping));

      expect(find.text('SLIPPING'), findsOneWidget);
      expect(find.text('2 of 5 gems current'), findsOneWidget);
    });

    testWidgets('before the board loads the row still opens the Hub',
        (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth(hunter: true);
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository());

      expect(find.byKey(const ValueKey('profile-reliability')), findsNothing);
      await tester.ensureVisible(find.text('Hunter Hub'));
      await tester.tap(find.text('Hunter Hub'));
      await tester.pumpAndSettle();
      expect(find.text('route /hunter-hub'), findsOneWidget);
    });
  });

  group('activity', () {
    final items = [
      activity('1', 'update.create', resourceId: 'u1'),
      activity('2', 'comment.create',
          resourceId: 'c1', metadata: {'updateId': 'u2'}),
      activity('3', 'project.follow',
          resourceId: 'f1', metadata: {'projectId': 'g1'}),
      activity('4', 'project_proposal.create', resourceId: 'pp1'),
      activity('5', 'radar.ack', resourceId: 'me'),
    ];

    testWidgets('each row opens its update, the comment\'s update or its gem',
        (tester) async {
      usePhone(tester);
      final opened = <ActivityTarget>[];
      final auth = FakeProfileAuth();
      await pumpProfile(
        tester,
        ProfileBody(
          auth: auth,
          onSignOut: () {},
          onOpenActivity: (_, target) => opened.add(target),
        ),
        auth: auth,
        users: FakeUsersRepository(activity: items),
      );

      for (final label in [
        'Posted an update',
        'Commented on an update',
        'Followed a gem',
        'Submitted a gem',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.pump();
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect(opened, const [
        ActivityTarget(ActivityTargetKind.update, 'u1'),
        ActivityTarget(ActivityTargetKind.update, 'u2'),
        ActivityTarget(ActivityTargetKind.gem, 'g1'),
      ]);
      // Radar acknowledgements are noise and are not listed.
      expect(find.textContaining('Radar'), findsNothing);
    });

    testWidgets('a failed read offers retry instead of "no activity"',
        (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      await pumpProfile(tester, _body(auth),
          auth: auth, users: FakeUsersRepository(failActivity: true));

      expect(find.text('Could not load activity'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No activity yet'), findsNothing);
      expect(find.textContaining('offline'), findsNothing);
    });

    testWidgets('long lists show five rows and expand', (tester) async {
      usePhone(tester);
      final auth = FakeProfileAuth();
      await pumpProfile(
        tester,
        _body(auth),
        auth: auth,
        users: FakeUsersRepository(activity: [
          for (var i = 0; i < 8; i++)
            activity('$i', 'update.create', resourceId: 'u$i'),
        ]),
      );

      expect(find.text('Posted an update'), findsNWidgets(5));
      await tester.ensureVisible(find.text('Show all (8)'));
      await tester.tap(find.text('Show all (8)'));
      await tester.pump();
      expect(find.text('Posted an update'), findsNWidgets(8));
    });
  });

  group('375px', () {
    for (final hunter in [false, true]) {
      testWidgets('the body lays out without overflow (hunter: $hunter)',
          (tester) async {
        usePhone(tester);
        final auth = FakeProfileAuth(hunter: hunter);
        await pumpProfile(
          tester,
          _body(auth),
          auth: auth,
          users: FakeUsersRepository(
            followingCount: 12345,
            watchlist: [for (var i = 0; i < 3; i++) followedGem('$i')],
            activity: [
              activity('1', 'community_post.comment.create',
                  resourceId: 'c', metadata: {'postId': 'p'}),
              activity('2', 'follow.preferences.update',
                  resourceId: 'f', metadata: {'projectId': 'g'}),
            ],
          ),
          board: hunter ? _board(current: 12, due: 3) : null,
        );

        expect(tester.takeException(), isNull);
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -2000));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Sign Out'), findsOneWidget);
      });
    }
  });
}
