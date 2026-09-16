import 'dart:async';

import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_saved_tab.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/comments_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/projects/update_reactions_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reactions_fixtures.dart';

void main() {
  late FakeReactionsRepository repo;
  late UpdateReactionsStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = FakeReactionsRepository();
    store = UpdateReactionsStore(repository: repo);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthStore>(
            create: (_) => AuthStore(
              enableSupabaseAuthListener: false,
              supabaseConfiguredOverride: false,
            ),
          ),
          ChangeNotifierProvider(create: (_) => CommentsStore()),
          ChangeNotifierProvider(create: (_) => LevelsStore()),
          ChangeNotifierProvider(create: (_) => EdgeEngineStore()),
          ChangeNotifierProvider(create: (_) => FeedViewModeStore()),
          ChangeNotifierProvider<UpdateReactionsStore>.value(value: store),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget card(Update post) => ListView(children: [FeedCard(post: post)]);

  group('FeedCard', () {
    testWidgets('shows the server like state and count', (tester) async {
      await pump(tester, card(reactionUpdate(likedByMe: true, likesCount: 9)));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('like flips at once and settles on the server count',
        (tester) async {
      repo
        ..likeGate = Completer<void>()
        ..serverLikes = 420;
      await pump(tester, card(reactionUpdate(likesCount: 412)));

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('413'), findsOneWidget);

      repo.likeGate!.complete();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('420'), findsOneWidget);
      expect(repo.calls, ['PUT like update-1']);
    });

    testWidgets('a failed like reverts and says so', (tester) async {
      repo
        ..likeGate = Completer<void>()
        ..failWrites = true;
      await pump(tester, card(reactionUpdate(likesCount: 412)));

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect(find.text('413'), findsOneWidget);

      repo.likeGate!.complete();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('412'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('Could not like update right now'), findsOneWidget);

      // Let the snackbar's dismiss timer run out.
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a failed save reverts and says so', (tester) async {
      repo.failWrites = true;
      await pump(tester, card(reactionUpdate(bookmarksCount: 7)));

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Could not update bookmark'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });
  });

  group('Profile Saved tab', () {
    testWidgets('lists what the server holds, not local storage',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        // A leftover local id must not appear on its own.
        'blocnet_update_bookmark_ids': ['local-only'],
      });
      repo.saved = [
        reactionUpdate(id: 's1', title: 'Snapshot moved', bookmarkedByMe: true),
        reactionUpdate(id: 's2', title: 'Claim is live', bookmarkedByMe: true),
      ];

      await pump(tester, const ProfileSavedTab(accent: Colors.teal));
      await tester.pump();

      expect(repo.calls, contains('GET saved'));
      expect(find.text('Snapshot moved'), findsOneWidget);
      expect(find.text('Claim is live'), findsOneWidget);
    });

    testWidgets('removing a save unsaves it on the server', (tester) async {
      repo.saved = [
        reactionUpdate(id: 's1', title: 'Snapshot moved', bookmarkedByMe: true),
      ];
      await pump(tester, const ProfileSavedTab(accent: Colors.teal));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.bookmark_remove_outlined));
      await tester.pump();

      expect(repo.calls, contains('DELETE bookmark s1'));
      expect(find.text('Snapshot moved'), findsNothing);
      expect(find.text('Bookmark updates to save them here'), findsOneWidget);
    });

    testWidgets('says the list failed rather than that it is empty',
        (tester) async {
      repo.failSaved = true;
      await pump(tester, const ProfileSavedTab(accent: Colors.teal));
      await tester.pump();

      expect(find.text('Could not load your saved updates'), findsOneWidget);
      expect(find.text('Bookmark updates to save them here'), findsNothing);
    });
  });
}
