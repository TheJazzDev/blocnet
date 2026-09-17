import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'community_fakes.dart';

/// The staff sheet shared by Community and the moderation Reports queue.
void main() {
  Future<List<CommunityContentModerationDecision?>> pumpSheet(
    WidgetTester tester, {
    required bool canArchive,
  }) async {
    usePhone(tester);
    final results = <CommunityContentModerationDecision?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showCommunityContentModerationSheet(
                  context,
                  targetLabel: 'comment',
                  canArchive: canArchive,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('offers archive only to those who may archive', (tester) async {
    await pumpSheet(tester, canArchive: false);
    expect(find.text('Moderate comment'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Only community admins can archive.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returns the action with its reason', (tester) async {
    final results = await pumpSheet(tester, canArchive: true);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Archive comment'), findsOneWidget);

    // Confirm waits for a reason.
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(results, isEmpty);

    await tester.enterText(find.byType(TextField), '  Repeated spam  ');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.status, CommunityContentModerationStatus.archived);
    expect(results.single!.reason, 'Repeated spam');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the reason returns nothing', (tester) async {
    final results = await pumpSheet(tester, canArchive: false);
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
