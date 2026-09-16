import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:blocnet/features/hunter/data/repositories/project_invites_api_repository.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/projects/project_invites_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hub_fixtures.dart';
import 'hub_harness.dart';

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

/// Serves the three reads the Hub makes, shaped like the backend.
class _Api extends ApiClient {
  _Api({required this.gems}) : super(httpClient: _NoopHttpClient());

  List<Map<String, dynamic>> gems;
  final List<String> calls = [];

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    calls.add('GET $path');
    switch (path) {
      case '/me/hunter/board':
        return {
          'reliability': {
            'profileId': 'me',
            'username': 'ada',
            'displayName': 'Ada',
            'standing': gems.isEmpty ? 'new' : 'reliable',
            'level': {'id': 'l9', 'slug': 'elite', 'name': 'Elite', 'level': 9},
            'responseAnswered': 3,
            'responseAsked': 3,
            'cadenceDays': 4,
            'gemsOwned': gems.length,
            'tipsReceivedTotal': '0',
            'membersWaiting': 0,
            'openReports': 0,
          },
          'gems': gems,
        };
      case '/project-invites/mine':
        return [
          {
            'id': 'inv-1',
            'projectId': 'p-nebula',
            'status': 'pending',
            'createdAt': '2026-09-15T00:00:00Z',
            'project': {'id': 'p-nebula', 'name': 'Nebula Swap'},
            'inviter': {'username': 'abtoonzz'},
          },
        ];
      case '/project-proposals/mine':
        return <Object>[];
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    calls.add('PATCH $path');
    gems = [_gemJson];
    return {
      'id': 'inv-1',
      'status': body!['status'],
      'createdAt': '2026-09-15T00:00:00Z',
      'project': {'id': 'p-nebula', 'name': 'Nebula Swap'},
    };
  }
}

final Map<String, dynamic> _gemJson = {
  'projectId': 'p-nebula',
  'name': 'Nebula Swap',
  'primaryTag': 'Solana',
  'followersCount': 12740,
  'listedAt': '2026-08-01T00:00:00Z',
  'lastActivityAt': '2026-09-15T10:00:00Z',
  'lastUpdate': {
    'id': 'u1',
    'title': 'Swap live',
    'publishedAt': '2026-09-15T10:00:00Z',
  },
  'daysQuiet': 1,
  'state': 'current',
  'membersWaiting': 0,
  'openReports': 0,
};

class _Notifications extends NotificationsStore {
  @override
  Future<void> refreshNotifications({String? category}) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
      'standalone: loads the board, shows day one with the invite, and '
      'accepting refreshes the board', (tester) async {
    usePhone(tester, 375);
    final api = _Api(gems: []);
    final board = HunterBoardStore(
      repository: HunterReliabilityApiRepository(apiClient: api),
      proposalsRepository: ProjectProposalsApiRepository(apiClient: api),
    );
    final invites = ProjectInvitesStore(
      repository: ProjectInvitesApiRepository(apiClient: api),
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>(
          create: (_) => AuthStore(
            enableSupabaseAuthListener: false,
            supabaseConfiguredOverride: false,
          ),
        ),
        ChangeNotifierProvider<NotificationsStore>(
            create: (_) => _Notifications()),
        ChangeNotifierProvider<HunterBoardStore>.value(value: board),
        ChangeNotifierProvider<ProjectInvitesStore>.value(value: invites),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HunterHubScreen(clock: () => hubNow),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(
        api.calls,
        containsAll([
          'GET /me/hunter/board',
          'GET /project-invites/mine',
          'GET /project-proposals/mine',
        ]));
    // Standalone: its own bar, titled Hub, with history and no settings.
    expect(find.text('Hub'), findsOneWidget);
    expect(byKey('hub-history'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.text('Submit a gem'), findsOneWidget, reason: 'day-one FAB');

    expect(byKey('hub-day-one'), findsOneWidget);
    expect(find.text('Co-own a gem already running'), findsOneWidget);
    expect(byKey('hub-invite-inv-1'), findsOneWidget);

    await tester.ensureVisible(find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('PATCH /project-invites/inv-1/respond'));
    expect(byKey('hub-invite-inv-1'), findsNothing);
    expect(byKey('hub-day-one'), findsNothing);
    expect(rowOf('p-nebula'), findsOneWidget);
    expect(find.text('Post update'), findsOneWidget, reason: 'FAB flips');
  });
}
