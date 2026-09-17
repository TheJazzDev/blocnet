import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/domain/gems_ordering.dart';
import 'package:blocnet/features/gems/presentation/widgets/discover/discover_view.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gems_fixtures.dart';

void main() {
  late ActionLog log;
  String? selectedTag;

  setUp(() {
    log = ActionLog();
    selectedTag = null;
  });

  Future<void> pump(
    WidgetTester tester, {
    GemsLoadState state = GemsLoadState.ready,
    List<GemListing> gems = const [],
    String? tag,
  }) async {
    usePhone(tester);
    await tester.pumpWidget(host(DiscoverView(
      state: state,
      gems: gems,
      sort: GemSort.mostActive,
      tag: tag,
      now: gemsNow,
      actions: log.actions,
      onSort: (_) {},
      onSelectTag: (t) => selectedTag = t,
      onRefresh: noRefresh,
    )));
    await tester.pump();
  }

  List<GemListing> sample() {
    final projects = [
      gemProject('g1',
          name: 'Core Mines',
          owner: admin('admin-1', username: 'ana'),
          updatesCount: 12,
          followers: 31,
          reliability: const OwnerReliability(
            profileId: 'admin-1',
            standing: ReliabilityStanding.reliable,
            coverage: 1,
          )),
      gemProject('g2',
          name: 'Sol Drop', tag: 'Solana', owner: admin('admin-2')),
    ];
    return GemListings.build(
      projects: projects,
      updates: [gemUpdate('u1', 'g1', title: 'KYC opened', at: daysAgo(2))],
      now: gemsNow,
    );
  }

  testWidgets('loading shows a spinner', (tester) async {
    await pump(tester, state: GemsLoadState.loading);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error offers a retry', (tester) async {
    await pump(tester, state: GemsLoadState.error);
    expect(find.text("Couldn't load gems"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('empty says nothing is listed', (tester) async {
    await pump(tester);
    expect(find.text('No gems listed yet'), findsOneWidget);
  });

  testWidgets('data: card answers what, alive, and who keeps it',
      (tester) async {
    await pump(tester, gems: sample());

    expect(find.text('MOVING ACROSS BLOCNET'), findsOneWidget);
    expect(find.text('2 GEMS'), findsOneWidget);
    expect(find.text('Core Mines'), findsNWidgets(2)); // moving + card
    expect(find.text('KYC opened'), findsNWidgets(2));
    expect(find.text(' · 2d ago'), findsOneWidget);
    expect(find.text('12 updates · 31 following'), findsOneWidget);
    // The reliability line.
    expect(find.text('Kept by @ana'), findsOneWidget);
    expect(find.text('100% of gems current'), findsOneWidget);
    expect(find.text('RELIABLE'), findsOneWidget);
    // No invented numbers, no dead controls.
    expect(find.textContaining('Hype'), findsNothing);
    expect(find.text('Most active'), findsOneWidget);
    // The second gem has no updates and no reliability.
    expect(find.text('No updates yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('keeper-admin-1')));
    await tester.tap(find.byKey(const ValueKey('gem-card-g2')));
    expect(log.calls, ['keeper:admin-1', 'open:g2']);
  });

  testWidgets('follow button toggles and shows preferences once followed',
      (tester) async {
    log.followed.add('g1');
    await pump(tester, gems: sample());
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gem-follow-prefs')));
    await tester.tap(find.text('Follow'));
    expect(log.calls, ['prefs:g1', 'follow:g2']);
  });

  testWidgets('chain filter selects a tag; no match offers to clear',
      (tester) async {
    await pump(tester, gems: sample());
    await tester.tap(find.byKey(const ValueKey('tag-chip-Solana')));
    expect(selectedTag, 'Solana');

    await pump(tester, gems: sample(), tag: 'Ethereum');
    expect(find.text('No Ethereum gems'), findsOneWidget);
    await tester.tap(find.text('Show all gems'));
    expect(selectedTag, isNull);
  });
}
