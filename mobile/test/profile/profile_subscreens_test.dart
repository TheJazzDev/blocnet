import 'package:blocnet/features/profile/presentation/pages/blocked_users_screen.dart';
import 'package:blocnet/features/profile/presentation/pages/deactivate_account_screen.dart';
import 'package:blocnet/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_harness.dart';

class _FakeBlocks extends BlocksStore {
  _FakeBlocks({this.users = const [], this.failure}) : super(ApiClient());

  final List<BlockedUser> users;
  final String? failure;

  @override
  List<BlockedUser> get blockedUsers => users;
  @override
  bool get isLoading => false;
  @override
  String? get error => failure;
  @override
  Future<void> fetchBlockedUsers() async {}
}

BlockedUser _blocked(String id, {String? name, String? username}) {
  return BlockedUser(
    id: 'b-$id',
    blockerId: 'me',
    blockedId: id,
    createdAt: DateTime(2026, 9, 1),
    blocked: BlockedUserProfile(
      id: id,
      username: username,
      displayName: name,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  BlocksStore? blocks,
}) async {
  usePhone(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>(create: (_) => FakeProfileAuth()),
        ChangeNotifierProvider(create: (_) => NotificationsStore()),
        ChangeNotifierProvider<BlocksStore>(
          create: (_) => blocks ?? _FakeBlocks(),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('edit profile fits 375px and shows the locked username',
      (tester) async {
    await _pump(tester, const EditProfileScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('@long_username_for_tests'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('blocked users lists names and handles', (tester) async {
    await _pump(
      tester,
      const BlockedUsersScreen(),
      blocks: _FakeBlocks(users: [
        _blocked('1',
            name: 'A very long blocked display name indeed',
            username: 'blocked_one'),
        _blocked('2', username: 'only_handle'),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('@blocked_one'), findsOneWidget);
    expect(find.text('only_handle'), findsOneWidget);
    expect(find.text('Unblock'), findsNWidgets(2));
  });

  testWidgets('blocked users says so plainly when nobody is blocked',
      (tester) async {
    await _pump(tester, const BlockedUsersScreen());
    expect(find.text('No one blocked'), findsOneWidget);
  });

  testWidgets('a failed load shows retry, not the raw error', (tester) async {
    await _pump(
      tester,
      const BlockedUsersScreen(),
      blocks: _FakeBlocks(failure: 'SocketException: host lookup failed'),
    );

    expect(find.text('Could not load blocked users'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets('deactivate fits 375px', (tester) async {
    await _pump(tester, const DeactivateAccountScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Deactivate account'), findsOneWidget);
    expect(find.text('Your data is kept'), findsOneWidget);
  });
}
