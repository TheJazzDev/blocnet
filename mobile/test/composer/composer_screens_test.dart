import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/pages/create_update_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/submit_project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'composer_fakes.dart';

void main() {
  group('Create Update at 375px', () {
    testWidgets('the form fits and validates', (tester) async {
      usePhone(tester);
      await pumpBehindLauncher(
        tester,
        const CreateUpdateScreen(),
        auth: FakeAuth(),
        tags: FakeTags(secondary: manyTags),
        projects: [longProject('p1')],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('GEM'), findsOneWidget);
      expect(find.text('URGENCY AND WINDOW'), findsOneWidget);
      expect(find.text(longName), findsOneWidget);

      await tester.tap(find.text('MINING'));
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      final page = find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(find.text('Publish Update'), 200,
          scrollable: page);
      await tester.tap(find.text('Publish Update'));
      await tester.pumpAndSettle();
      expect(find.text('Content is required'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Title is required'), -200,
          scrollable: page);
      expect(find.text('Title is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no gem to post to offers Submit a new gem', (tester) async {
      usePhone(tester);
      await pumpBehindLauncher(
        tester,
        const CreateUpdateScreen(),
        auth: FakeAuth(),
        tags: FakeTags(),
      );
      expect(find.text('No gem to post to yet'), findsOneWidget);
      expect(find.text('Submit a new gem'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a role that cannot post says so', (tester) async {
      usePhone(tester);
      await pumpBehindLauncher(
        tester,
        const CreateUpdateScreen(),
        auth: FakeAuth(allowed: false),
        tags: FakeTags(),
      );
      expect(find.text("Your role can't post updates"), findsOneWidget);
    });
  });

  group('Submit New Gem at 375px', () {
    const chains = [
      PrimaryTag(id: 'c1', name: 'Binance Smart Chain Network And More'),
      PrimaryTag(id: 'c2', name: 'Solana'),
    ];

    testWidgets('the form fits, validates and sends trimmed values',
        (tester) async {
      usePhone(tester, height: 1400);
      final sent = <Map<String, Object?>>[];
      await pumpBehindLauncher(
        tester,
        SubmitProjectScreen(
          submit: ({
            required name,
            symbol,
            websiteUrl,
            required description,
            required primaryTagId,
            reason,
          }) async {
            sent.add({
              'name': name,
              'symbol': symbol,
              'websiteUrl': websiteUrl,
              'description': description,
              'primaryTagId': primaryTagId,
              'reason': reason,
            });
            return {'id': 'prop-1'};
          },
        ),
        auth: FakeAuth(),
        tags: FakeTags(primary: chains),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('THE GEM'), findsOneWidget);
      expect(find.text('Binance Smart Chain Network And More'), findsOneWidget);

      await tester.tap(find.text('Submit for approval'));
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('submit-name')), '  Codawoo ');
      await tester.enterText(
          find.byKey(const ValueKey('submit-website')), 'not a site');
      await tester.enterText(find.byKey(const ValueKey('submit-description')),
          'Mining rewards on a new chain.');
      await tester.tap(find.text('Submit for approval'));
      await tester.pumpAndSettle();
      expect(
          find.text('Enter a web address, like example.com'), findsOneWidget);
      expect(sent, isEmpty);

      await tester.enterText(
          find.byKey(const ValueKey('submit-website')), 'codawoo.io');
      await tester.tap(find.text('Submit for approval'));
      await tester.pumpAndSettle();
      expect(sent.single, {
        'name': 'Codawoo',
        'symbol': null,
        'websiteUrl': 'codawoo.io',
        'description': 'Mining rewards on a new chain.',
        'primaryTagId': 'c1',
        'reason': null,
      });
      expect(find.text('THE GEM'), findsNothing, reason: 'popped');
    });

    testWidgets('a failed send is stated without the Exception prefix',
        (tester) async {
      usePhone(tester, height: 1400);
      await pumpBehindLauncher(
        tester,
        SubmitProjectScreen(
          submit: ({
            required name,
            symbol,
            websiteUrl,
            required description,
            required primaryTagId,
            reason,
          }) async =>
              throw Exception('A gem with this name exists'),
        ),
        auth: FakeAuth(),
        tags: FakeTags(primary: chains),
      );
      await tester.enterText(
          find.byKey(const ValueKey('submit-name')), 'Codawoo');
      await tester.enterText(find.byKey(const ValueKey('submit-description')),
          'Mining rewards on a new chain.');
      await tester.tap(find.text('Submit for approval'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('composer-error')), findsOneWidget);
      expect(find.text('A gem with this name exists'), findsOneWidget);
    });

    testWidgets('a failed chain read offers a retry, not "not configured"',
        (tester) async {
      usePhone(tester);
      final tags = FakeTags(error: 'offline');
      await pumpBehindLauncher(
        tester,
        const SubmitProjectScreen(),
        auth: FakeAuth(),
        tags: tags,
      );
      expect(find.text("Couldn't load chains"), findsOneWidget);
      tags
        ..error = null
        ..primary = chains;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(tags.refreshes, 1);
      expect(find.text('THE GEM'), findsOneWidget);
    });

    testWidgets('no chains says so', (tester) async {
      usePhone(tester);
      await pumpBehindLauncher(
        tester,
        const SubmitProjectScreen(),
        auth: FakeAuth(),
        tags: FakeTags(),
      );
      expect(find.text('No chains set up yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a role that cannot submit says so', (tester) async {
      usePhone(tester);
      await pumpBehindLauncher(
        tester,
        const SubmitProjectScreen(),
        auth: FakeAuth(allowed: false),
        tags: FakeTags(),
      );
      expect(find.text("Your role can't submit gems"), findsOneWidget);
    });
  });
}
