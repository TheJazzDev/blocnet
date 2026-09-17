import 'package:blocnet/features/moderation/presentation/pages/appeals_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/pages/reports_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_button.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_dialog.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

Map<String, dynamic> _reportJson(String id, {String status = 'open'}) => {
      'id': id,
      'reporterId': 'r1',
      'targetType': 'community_post',
      'targetId': 'post-$id',
      'targetUserId': 'u1',
      'reason': 'Harassment or bullying of another member in the thread',
      'details': 'Called another member names in three replies.',
      'status': status,
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toUtc()
          .toIso8601String(),
      'updatedAt': '2026-09-10T08:00:00.000Z',
      'reporter': {
        'id': 'r1',
        'email': 'reporter@example.com',
        'displayName': 'Reporter With A Rather Long Display Name',
      },
      'targetUser': {
        'id': 'u1',
        'email': 'target@example.com',
        'username': 'target_user_with_long_handle',
      },
    };

Map<String, dynamic> _appealJson(String id, {String status = 'pending'}) => {
      'id': id,
      'reportId': 'rep1',
      'appealerId': 'u1',
      'reason': 'I was quoting the other member, not insulting them.',
      'status': status,
      'createdAt': '2026-09-12T08:00:00.000Z',
      'updatedAt': '2026-09-12T08:00:00.000Z',
      'appealer': {'id': 'u1', 'username': 'ada'},
      'report': {
        'id': 'rep1',
        'reporterId': 'r1',
        'targetType': 'post',
        'targetId': 'p1',
        'category': 'harassment',
        'status': 'approved',
        'createdAt': '2026-09-10T08:00:00.000Z',
        'updatedAt': '2026-09-10T08:00:00.000Z',
      },
    };

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(httpClient: _NoopHttpClient());

  bool fail = false;
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> appeals = [];
  final List<Map<String, String>?> reportQueries = [];
  final List<String> patchedPaths = [];
  final List<Map<String, dynamic>?> patched = [];

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    if (fail) throw ApiException('Server error', statusCode: 500);
    if (path == '/community/moderation/reports') {
      reportQueries.add(query);
      return {
        'data': reports,
        'total': reports.length,
        'limit': 20,
        'offset': 0,
      };
    }
    if (path == '/community/moderation/appeals') {
      return {'appeals': appeals};
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    patchedPaths.add(path);
    patched.add(body);
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

/// The success toast dismisses itself on a 3s timer.
Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  group('ReportsQueueScreen', () {
    testWidgets('lists reports with pills and actions, no overflow at 375px',
        (tester) async {
      final api = _FakeApiClient()
        ..reports = [_reportJson('a'), _reportJson('b', status: 'resolved')];
      await _pump(tester, ReportsQueueScreen(apiClient: api));

      expect(tester.takeException(), isNull);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('RESOLVED'), findsOneWidget);
      expect(find.text('POST'), findsNWidgets(2));
      expect(find.text('3 hours ago'), findsNWidgets(2));
      // Only the open report can be resolved or dismissed.
      expect(find.widgetWithText(ModButton, 'Resolve'), findsOneWidget);
      expect(find.widgetWithText(ModButton, 'Dismiss'), findsOneWidget);
      expect(find.text('1–2 of 2'), findsOneWidget);
    });

    testWidgets('a failed load shows a readable error with retry',
        (tester) async {
      final api = _FakeApiClient()..fail = true;
      await _pump(tester, ReportsQueueScreen(apiClient: api));

      expect(find.text('Reports did not load'), findsOneWidget);
      expect(find.textContaining('Instance of'), findsNothing);

      api
        ..fail = false
        ..reports = [_reportJson('a')];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('search waits for typing to stop, then loads once',
        (tester) async {
      final api = _FakeApiClient();
      await _pump(tester, ReportsQueueScreen(apiClient: api));
      expect(api.reportQueries, hasLength(1));

      await tester.enterText(find.byType(TextField), 'sp');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'spam');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(api.reportQueries, hasLength(2));
      expect(api.reportQueries.last?['q'], 'spam');
    });

    testWidgets('resolving sends the note and reloads', (tester) async {
      final api = _FakeApiClient()..reports = [_reportJson('a')];
      await _pump(tester, ReportsQueueScreen(apiClient: api));

      await tester.tap(find.widgetWithText(ModButton, 'Resolve'));
      await tester.pumpAndSettle();
      expect(find.byType(ModDialog), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(ModDialog),
          matching: find.byType(TextField),
        ),
        ' Removed the replies ',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(ModDialog),
          matching: find.widgetWithText(ModButton, 'Resolve'),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.patchedPaths.single, '/community/moderation/reports/a');
      expect(api.patched.single, {
        'status': 'resolved',
        'note': 'Removed the replies',
      });
      expect(api.reportQueries, hasLength(2));
      expect(find.text('Report resolved'), findsOneWidget);
      await _drainToast(tester);
    });
  });

  group('AppealsQueueScreen', () {
    testWidgets('lists appeals with the original report, no overflow',
        (tester) async {
      final api = _FakeApiClient()
        ..appeals = [_appealJson('x'), _appealJson('y', status: 'approved')];
      await _pump(tester, AppealsQueueScreen(apiClient: api));

      expect(tester.takeException(), isNull);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('ada'), findsNWidgets(2));
      expect(find.text('ORIGINAL REPORT'), findsNWidgets(2));
      expect(find.widgetWithText(ModButton, 'Overturn'), findsOneWidget);
      expect(find.widgetWithText(ModButton, 'Uphold'), findsOneWidget);
    });

    testWidgets('a failed load says so instead of "no appeals"',
        (tester) async {
      final api = _FakeApiClient()..fail = true;
      await _pump(tester, AppealsQueueScreen(apiClient: api));

      expect(find.text('Appeals did not load'), findsOneWidget);
      expect(find.text('No appeals'), findsNothing);
    });

    testWidgets('upholding patches the decision and says so', (tester) async {
      final api = _FakeApiClient()..appeals = [_appealJson('x')];
      await _pump(tester, AppealsQueueScreen(apiClient: api));

      await tester.tap(find.widgetWithText(ModButton, 'Uphold'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ModDialog),
          matching: find.widgetWithText(ModButton, 'Uphold'),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.patchedPaths.single, '/community/moderation/appeals/x');
      expect(api.patched.single, {'decision': 'uphold'});
      expect(find.text('Decision upheld'), findsOneWidget);
      await _drainToast(tester);
    });
  });
}
