import 'package:blocnet/features/gems/presentation/widgets/hunters/hunters_view.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/services/gems/hunter_leaderboard_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gems_fixtures.dart';

void main() {
  final opened = <String>[];
  var more = 0;

  setUp(() {
    opened.clear();
    more = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    GemsLoadState state = GemsLoadState.ready,
    List<HunterLeaderboardEntry> entries = const [],
    bool hasMore = false,
  }) async {
    usePhone(tester);
    await tester.pumpWidget(host(HuntersView(
      state: state,
      entries: entries,
      yourHunterIds: const {'h-2'},
      hasMore: hasMore,
      isLoadingMore: false,
      onOpen: (k) => opened.add(k.profileId),
      onLoadMore: () => more++,
      onRefresh: noRefresh,
    )));
    await tester.pump();
  }

  testWidgets('loading shows a spinner', (tester) async {
    await pump(tester, state: GemsLoadState.loading);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error offers a retry', (tester) async {
    await pump(tester, state: GemsLoadState.error);
    expect(find.text("Couldn't load hunters"), findsOneWidget);
  });

  testWidgets('empty says nobody is ranked', (tester) async {
    await pump(tester);
    expect(find.text('No hunters ranked yet'), findsOneWidget);
  });

  testWidgets('ranking keeps the server order and shows the numbers',
      (tester) async {
    await pump(tester, hasMore: true, entries: [
      ranked(1, hunter('h-1', name: 'Ana Keeper', gems: 5, coverage: 0.8)),
      ranked(
          2,
          hunter('h-2',
              name: 'Bo Slips',
              standing: ReliabilityStanding.slipping,
              coverage: 0.5,
              gems: 4,
              answered: 1,
              asked: 3)),
      ranked(
          3,
          hunter('h-3',
              name: 'Cy New',
              standing: ReliabilityStanding.newHunter,
              coverage: null,
              gems: 1,
              answered: null,
              asked: null,
              followers: 0)),
    ]);

    expect(find.text('RANKED BY RELIABILITY'), findsOneWidget);
    final ys = ['#1', '#2', '#3']
        .map((r) => tester.getTopLeft(find.text(r)).dy)
        .toList();
    expect(ys[0], lessThan(ys[1]));
    expect(ys[1], lessThan(ys[2]));

    expect(find.text('4 of 5 gems current'), findsOneWidget);
    expect(find.text('Answered 4 of 5 asks · 1,204 following'), findsOneWidget);
    expect(find.text('2 of 4 gems current'), findsOneWidget);
    expect(find.text('RELIABLE'), findsOneWidget);
    expect(find.text('SLIPPING'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('1 gem'), findsOneWidget);
    // Only Bo keeps a gem the member follows.
    expect(find.byKey(const ValueKey('keeps-your-gems')), findsOneWidget);

    await tester.tap(find.text('Bo Slips'));
    await tester.tap(find.text('Show more hunters'));
    expect(opened, ['h-2']);
    expect(more, 1);
  });

  test('store pages through the leaderboard', () async {
    final cursors = <String?>[];
    final store = HunterLeaderboardStore(fetch: ({int limit = 20, cursor}) {
      cursors.add(cursor);
      return Future.value(HunterLeaderboardPage(
        entries: [ranked(cursors.length, hunter('h-${cursors.length}'))],
        nextCursor: cursors.length == 1 ? '50' : null,
      ));
    });

    await store.loadOnce();
    expect(store.entries, hasLength(1));
    expect(store.hasMore, isTrue);
    await store.loadMore();
    expect(store.entries, hasLength(2));
    expect(store.hasMore, isFalse);
    expect(cursors, [null, '50']);
    expect(store.byProfileId.keys, ['h-1', 'h-2']);
  });

  test('store keeps the error when the first read fails', () async {
    final store = HunterLeaderboardStore(
      fetch: ({int limit = 20, cursor}) => Future.error(Exception('offline')),
    );
    await store.refresh();
    expect(store.error, isNotNull);
    expect(store.hasLoaded, isFalse);
  });
}
