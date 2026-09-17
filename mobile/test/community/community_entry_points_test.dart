import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/presentation/pages/my_reports_screen.dart';
import 'package:blocnet/features/community/presentation/widgets/community_tabs.dart';
import 'package:blocnet/features/community/presentation/widgets/report/community_report_sheet.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'community_fakes.dart';

/// My reports used to be reachable only from Profile › Settings › Privacy,
/// and Saved posts from nowhere. Both now open from Community itself.
void main() {
  late CommunityPostsStore store;

  setUp(() {
    store = CommunityPostsStore(repository: FakePostsRepository());
  });

  Future<List<String>> pumpTabs(WidgetTester tester) async {
    usePhone(tester);
    final pushed = <String>[];
    await tester.pumpWidget(
      communityHost(
        store: store,
        pushed: pushed,
        wrapInScaffold: true,
        child: DefaultTabController(
          length: 2,
          child: Builder(
            builder: (context) => CommunityTabs(
              controller: DefaultTabController.of(context),
              accentColor: Colors.cyan,
            ),
          ),
        ),
      ),
    );
    return pushed;
  }

  test('Saved and My reports are registered routes', () {
    final routes = ProtectedRoutes.getAll();
    expect(routes.containsKey(AppRoutes.communitySaved), isTrue);
    expect(routes.containsKey(AppRoutes.myReports), isTrue);
    expect(ProtectedRoutes.isProtectedRoute(AppRoutes.communitySaved), isTrue);
  });

  testWidgets('the Community overflow opens My reports', (tester) async {
    final pushed = await pumpTabs(tester);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('My reports'), findsOneWidget);
    expect(find.text('Saved posts'), findsOneWidget);

    await tester.tap(find.text('My reports'));
    await tester.pumpAndSettle();
    expect(pushed, [AppRoutes.myReports]);
  });

  testWidgets('the bookmark beside the tabs opens Saved', (tester) async {
    final pushed = await pumpTabs(tester);

    await tester.tap(find.byTooltip('Saved'));
    await tester.pumpAndSettle();
    expect(pushed, [AppRoutes.communitySaved]);
  });

  testWidgets('a sent report offers a shortcut to My reports', (tester) async {
    usePhone(tester);
    final pushed = <String>[];
    final moderation = FakeModerationRepository();
    await tester.pumpWidget(
      communityHost(
        store: store,
        pushed: pushed,
        wrapInScaffold: true,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => openCommunityReportSheet(
              context,
              targetType: CommunityReportTargetType.communityPost,
              targetId: 'post-1',
              content: 'Buy my coin',
              repository: moderation,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Report post'), findsOneWidget);

    await tester.tap(find.text('Spam or promotional content'));
    await tester.pump();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(moderation.lastReport?.targetId, 'post-1');
    expect(moderation.lastReport?.reason, 'Spam or promotional content');
    expect(find.text('Report post'), findsNothing); // sheet closed
    expect(find.text('Report sent'), findsOneWidget);

    await tester.tap(find.text('My reports'));
    await tester.pumpAndSettle();
    expect(pushed, [AppRoutes.myReports]);
  });

  group('My reports', () {
    Future<FakeModerationRepository> pumpReports(
      WidgetTester tester,
      void Function(FakeModerationRepository repo) script,
    ) async {
      usePhone(tester);
      final repo = FakeModerationRepository();
      script(repo);
      await tester.pumpWidget(
        communityHost(store: store, child: MyReportsScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('lists the member’s own reports with server counts',
        (tester) async {
      final repo = await pumpReports(tester, (repo) {
        repo.page = CommunityModerationReportsPage(
          reports: [
            report(id: 'r1', details: 'Same link posted five times'),
            report(
              id: 'r2',
              status: CommunityReportStatus.resolved,
              reason: 'Harassment or bullying',
              note: 'Post removed',
            ),
          ],
          total: 2,
          limit: 20,
          offset: 0,
          counts: const CommunityReportCounts(
            open: 4,
            resolved: 9,
            dismissed: 1,
          ),
        );
      });

      // It reads the member's own list, never the staff queue.
      expect(repo.myReportCalls, 1);
      expect(repo.staffListCalls, 0);
      expect(find.text('YOUR REPORTS · 14'), findsOneWidget);
      expect(find.text('4 open'), findsOneWidget);
      expect(find.text('9 resolved'), findsOneWidget);
      expect(find.text('Same link posted five times'), findsOneWidget);
      expect(find.text('Harassment or bullying'), findsOneWidget);
      expect(find.text('Post removed'), findsOneWidget);
    });

    testWidgets('says so when there are none', (tester) async {
      await pumpReports(tester, (repo) {
        repo.page = const CommunityModerationReportsPage(
          reports: [],
          total: 0,
          limit: 20,
          offset: 0,
        );
      });
      expect(find.text('No reports yet'), findsOneWidget);
    });

    testWidgets('shows a readable error and retries', (tester) async {
      final repo = await pumpReports(tester, (repo) {
        repo.error = ApiException('Server is down', statusCode: 503);
      });
      expect(find.text('Couldn’t load your reports'), findsOneWidget);
      expect(find.text('Server is down'), findsNothing);

      repo
        ..error = null
        ..page = CommunityModerationReportsPage(
          reports: [report(id: 'r1')],
          total: 1,
          limit: 20,
          offset: 0,
        );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(repo.myReportCalls, 2);
      expect(find.text('1 open'), findsOneWidget);
    });
  });
}
