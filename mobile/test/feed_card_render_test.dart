import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/comments_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Renders a real [FeedCard] at a real phone width, at each priority and in
/// both layouts.
///
/// This exists because three defects shipped past a clean analyzer and a full
/// unit suite, and only showed up on a device:
///
/// * the urgency edge was a stretched [Row] child with no height to stretch to
///   inside a sliver, which collapsed the feed to blank **with no exception**;
/// * `_ActionButton` carried a fixed 64px width that overflowed the row by
///   62px once Tip became a fifth element;
/// * the whole redesign initially landed only on the non-default layout.
///
/// A widget test at a fixed 390px width catches all three classes, because in
/// `flutter test` an overflow is a test failure rather than a yellow stripe.
void main() {
  // iPhone-class logical width, which is what the design is drawn at.
  const phone = Size(390, 844);

  Update updateWith(Priority priority,
      {String title = 'KYC opens for Phase 2'}) {
    final admin = Admin(
      id: 'author-1',
      name: 'Jazzdev',
      username: 'jazzdev',
      imageUrl: '',
      followers: 12,
      roles: const ['hunter'],
    );
    final project = Project(
      id: 'project-1',
      logo: '',
      name: 'Core Mines',
      details: 'Mining on Core',
      adminId: 'author-1',
      createdAt: DateTime(2026, 9, 1),
      primaryTagId: 'tag-1',
      primaryTag: const PrimaryTag(id: 'tag-1', name: 'Core', slug: 'core'),
      description: 'Mining and node operation opportunities on Core',
      followersCount: 8412,
    );
    return Update(
      id: 'update-1',
      title: title,
      content: 'Use the same wallet you mined with, or you drop out entirely.',
      description:
          'Use the same wallet you mined with, or you drop out entirely.',
      adminId: 'author-1',
      projectId: 'project-1',
      priority: priority,
      createdAt: DateTime(2026, 9, 12),
      admin: admin,
      project: project,
      likesCount: 412,
      commentsCount: 58,
      bookmarksCount: 7,
      secondaryTagIds: const ['tag-mining', 'tag-airdrops'],
      secondaryTags: const [
        SecondaryTag(id: 'tag-mining', name: 'Mining', slug: 'mining'),
        SecondaryTag(id: 'tag-airdrops', name: 'Airdrops', slug: 'airdrops'),
      ],
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    Update post, {
    FeedCardLayout layout = FeedCardLayout.list,
  }) async {
    tester.view.physicalSize = phone;
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
        ],
        child: MaterialApp(
          home: Scaffold(
            // A sliver, because the collapsed-edge bug only appeared under
            // one: a Row stretched on its cross axis has no height there.
            body: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    FeedCard(post: post, layout: layout),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  for (final layout in FeedCardLayout.values) {
    group('FeedCard renders in ${layout.name} layout', () {
      for (final priority in [Priority.high, Priority.mid, Priority.low]) {
        testWidgets('at ${priority.label} priority, without overflowing',
            (tester) async {
          await pumpCard(tester, updateWith(priority), layout: layout);

          // An overflow is a test failure here, not a yellow stripe, so
          // reaching this line at all is the assertion that matters most.
          expect(tester.takeException(), isNull);

          // The card has real height. The collapsed-edge bug produced a
          // zero-height row that threw nothing at all.
          final size = tester.getSize(find.byType(FeedCard));
          expect(size.height, greaterThan(100));
          expect(size.width, lessThanOrEqualTo(phone.width));
        });
      }

      testWidgets('shows the update title, which the feed used to discard',
          (tester) async {
        await pumpCard(
          tester,
          updateWith(Priority.high, title: 'Snapshot moved to Friday'),
          layout: layout,
        );
        expect(find.text('Snapshot moved to Friday'), findsOneWidget);
      });

      testWidgets('a high-priority card is taller than a low-priority one',
          (tester) async {
        await pumpCard(tester, updateWith(Priority.low), layout: layout);
        final lowHeight = tester.getSize(find.byType(FeedCard)).height;

        await pumpCard(tester, updateWith(Priority.high), layout: layout);
        final highHeight = tester.getSize(find.byType(FeedCard)).height;

        // The point of the round-six treatment: urgency is felt as mass
        // before any word is read. The title grows from 15 to 20px, so the
        // card cannot be the same height.
        expect(highHeight, greaterThan(lowHeight));
      });

      testWidgets('offers Tip when the reader is not the author',
          (tester) async {
        await pumpCard(tester, updateWith(Priority.high), layout: layout);
        expect(find.text('Tip'), findsOneWidget);
      });
    });
  }
}
