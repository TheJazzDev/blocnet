import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
import 'package:blocnet/features/moderation/presentation/pages/inactive_gems_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/pages/moderation_hub_screen.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/resolve_inactive_gem_dialog.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

Map<String, dynamic> _gemJson(String id, String name, {int reports = 2}) => {
      'project': {
        'id': id,
        'name': name,
        'slug': name.toLowerCase(),
        'status': 'active',
        'primaryTag': 'DeFi',
        'listedAt': '2026-07-01T00:00:00.000Z',
      },
      'hunters': [
        {
          'id': 'h1',
          'username': 'ada',
          'displayName': 'Ada',
          'avatarUrl': null,
          'standing': 'quiet',
          'coverage': 0.25,
        },
      ],
      'openReports': reports,
      'firstReportedAt': '2026-09-10T08:00:00.000Z',
      'lastActivityAt': '2026-08-20T08:00:00.000Z',
      'daysQuiet': 27,
      'membersWaiting': 3,
    };

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(httpClient: _NoopHttpClient());

  bool failStats = false;
  int statsCalls = 0;
  List<Map<String, dynamic>> gems = [];
  final List<Map<String, dynamic>?> posted = [];
  final List<String> postedPaths = [];

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    if (path == '/community/moderation/stats') {
      statsCalls += 1;
      if (failStats) {
        throw ApiException('Server error', statusCode: 500);
      }
      return {
        'pendingReports': 4,
        'pendingAppeals': 1,
        'activeRestrictions': 0,
        'openInactiveGems': gems.length,
      };
    }
    if (path == '/community/moderation/inactive-gems') {
      return {'data': gems, 'total': gems.length, 'limit': 50, 'offset': 0};
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    postedPaths.add(path);
    posted.add(body);
    gems = [];
    return {'ok': true};
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pumpAndSettle();
}

void main() {
  group('InactiveGemReport.listFromApi', () {
    test('parses the queue envelope', () {
      final rows = InactiveGemReport.listFromApi({
        'data': [_gemJson('p1', 'Alpha', reports: 5)],
        'total': 1,
      });
      final gem = rows.single;
      expect(gem.projectId, 'p1');
      expect(gem.projectName, 'Alpha');
      expect(gem.openReports, 5);
      expect(gem.daysQuiet, 27);
      expect(gem.membersWaiting, 3);
      expect(gem.firstReportedAt, DateTime.utc(2026, 9, 10, 8));
      expect(gem.hunters.single.name, 'Ada');
      expect(gem.hunters.single.standing, ReliabilityStanding.quiet);
      expect(gem.hunters.single.coverage, 0.25);
    });

    test('an unexpected payload is an empty queue', () {
      expect(InactiveGemReport.listFromApi(null), isEmpty);
      expect(InactiveGemReport.listFromApi(const ['x']), isEmpty);
    });
  });

  group('ModerationHubScreen', () {
    testWidgets('shows an error with retry, not zeros, when stats fail',
        (tester) async {
      final api = _FakeApiClient()..failStats = true;
      await _pump(tester, Scaffold(body: ModerationHubScreen(apiClient: api)));

      expect(find.text('Queue counts did not load'), findsOneWidget);
      // No made-up zeros: no count pills, and restrictions read as unknown.
      expect(find.byType(ModPill), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Quiet gems reported'), findsOneWidget);
      expect(tester.takeException(), isNull);

      api.failStats = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Queue counts did not load'), findsNothing);
      expect(find.widgetWithText(ModPill, '4'), findsOneWidget);
      expect(find.widgetWithText(ModPill, '1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget, reason: 'active restrictions');
      expect(find.text('—'), findsNothing);
    });

    testWidgets('shows each queue once with its count, no overflow at 375px',
        (tester) async {
      final api = _FakeApiClient()
        ..gems = [_gemJson('p1', 'Alpha'), _gemJson('p2', 'Beta')];
      await _pump(tester, Scaffold(body: ModerationHubScreen(apiClient: api)));

      expect(tester.takeException(), isNull);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Appeals'), findsOneWidget);
      expect(find.text('Quiet gems reported'), findsOneWidget);
      expect(find.text('Active restrictions'), findsOneWidget);
      // Each count appears exactly once on the hub.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
      expect(find.byType(ModPill), findsNWidgets(3));
    });

    testWidgets('opens the quiet gems queue and reloads stats on return',
        (tester) async {
      final api = _FakeApiClient()..gems = [_gemJson('p1', 'Alpha')];
      await _pump(tester, Scaffold(body: ModerationHubScreen(apiClient: api)));
      expect(api.statsCalls, 1);

      await tester.tap(find.text('Quiet gems reported'));
      await tester.pumpAndSettle();
      expect(find.text('Quiet Gems Reported'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(api.statsCalls, 2);
    });
  });

  group('InactiveGemsQueueScreen', () {
    testWidgets('lists reported gems with their hunter standing',
        (tester) async {
      final api = _FakeApiClient()..gems = [_gemJson('p1', 'Alpha')];
      await _pump(tester, InactiveGemsQueueScreen(apiClient: api));

      expect(find.text('2 REPORTS'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(
        find.text('Quiet 27 days · 3 members waiting · DeFi'),
        findsOneWidget,
      );
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Quiet · 25% current'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty state when nothing is reported',
        (tester) async {
      await _pump(tester, InactiveGemsQueueScreen(apiClient: _FakeApiClient()));
      expect(find.text('No quiet gems reported'), findsOneWidget);
    });

    testWidgets('resolve needs an outcome and a note, then posts both',
        (tester) async {
      final api = _FakeApiClient()..gems = [_gemJson('p1', 'Alpha')];
      await _pump(tester, InactiveGemsQueueScreen(apiClient: api));

      await tester.tap(find.widgetWithText(AppButton, 'Resolve'));
      await tester.pumpAndSettle();

      final submit = find.descendant(
        of: find.byType(ResolveInactiveGemDialog),
        matching: find.widgetWithText(AppButton, 'Resolve'),
      );
      expect(tester.widget<AppButton>(submit).onPressed, isNull);

      await tester.tap(find.text('Hunter contacted'));
      await tester.pump();
      expect(tester.widget<AppButton>(submit).onPressed, isNull,
          reason: 'a note is required');

      await tester.enterText(find.byType(TextField), '  Pinged on Telegram ');
      await tester.pump();
      expect(tester.widget<AppButton>(submit).onPressed, isNotNull);

      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(api.postedPaths.single,
          '/community/moderation/inactive-gems/p1/resolve');
      expect(api.posted.single, {
        'outcome': 'hunter_contacted',
        'note': 'Pinged on Telegram',
      });
      expect(find.text('Reports on Alpha resolved'), findsOneWidget);
      expect(find.text('No quiet gems reported'), findsOneWidget);
    });

    testWidgets('cancelling the dialog posts nothing', (tester) async {
      final api = _FakeApiClient()..gems = [_gemJson('p1', 'Alpha')];
      await _pump(tester, InactiveGemsQueueScreen(apiClient: api));

      await tester.tap(find.widgetWithText(AppButton, 'Resolve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.posted, isEmpty);
      expect(find.text('Alpha'), findsOneWidget);
    });
  });
}
