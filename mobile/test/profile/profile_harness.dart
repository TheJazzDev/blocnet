import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/projects/update_reactions_store.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../update_reactions/reactions_fixtures.dart';

class FakeProfileAuth extends AuthStore {
  FakeProfileAuth({this.hunter = false})
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  final bool hunter;

  @override
  String? get userId => 'me';
  @override
  String? get displayName => 'A member with a rather long display name';
  @override
  String? get email => 'member.with.a.long.address@blocnet.app';
  @override
  String? get username => 'long_username_for_tests';
  @override
  String? get bio => 'Watching gems. ' * 8;
  @override
  bool get hasHunterSpace => hunter;
}

class FakeUsersRepository extends UsersApiRepository {
  FakeUsersRepository({
    this.followingCount = 0,
    this.watchlist = const [],
    this.activity = const [],
    this.failActivity = false,
  });

  final int followingCount;
  final List<Project> watchlist;
  final List<ActivityItem> activity;
  final bool failActivity;

  @override
  Future<Map<String, dynamic>?> fetchMe({bool forceRefresh = false}) async =>
      {'followingCount': followingCount};

  @override
  Future<List<Project>> fetchWatchlist(
          {int limit = 100, int offset = 0}) async =>
      watchlist;

  @override
  Future<List<ActivityItem>> fetchActivity({
    int limit = 100,
    int offset = 0,
  }) async {
    if (failActivity) throw Exception('offline');
    return activity;
  }

  @override
  Future<List<CommunityPost>> fetchBookmarks({
    int limit = 100,
    int offset = 0,
  }) async =>
      const [];
}

class QuietTipsStore extends TipsStore {
  @override
  Future<void> loadOverview({bool force = false}) async {}
  @override
  Future<void> loadSentHistory({
    bool force = false,
    int limit = 50,
    int offset = 0,
    String? currencyCode,
  }) async {}
}

class QuietBadgesStore extends BadgesStore {
  @override
  Future<void> loadMyBadges({bool force = false}) async {}
}

class QuietLevelsStore extends LevelsStore {
  @override
  Future<void> fetchAllLevels() async {}
  @override
  Future<void> fetchMyProgress() async {}
}

/// Serves a fixed board without touching the network.
class FixedBoardStore extends HunterBoardStore {
  FixedBoardStore(this._fixed);

  final HunterBoard? _fixed;

  @override
  HunterBoard? get board => _fixed;
  @override
  Future<void> loadBoard() async {}
}

Project followedGem(String id) =>
    Project.fromApi({'id': id, 'name': 'Gem $id', 'description': 'd'});

ActivityItem activity(
  String id,
  String action, {
  String? resourceId,
  Map<String, dynamic>? metadata,
}) {
  return ActivityItem(
    id: id,
    action: action,
    resourceType: 'x',
    resourceId: resourceId,
    metadata: metadata,
    createdAt: DateTime(2026, 9, 16, 11),
  );
}

void usePhone(WidgetTester tester, {double width = 375}) {
  tester.view.physicalSize = Size(width * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps [child] with every store the profile body reads. [selectedTabs]
/// records main-tab switches made through [MainTabScope].
Future<void> pumpProfile(
  WidgetTester tester,
  Widget child, {
  required AuthStore auth,
  required UsersApiRepository users,
  HunterBoard? board,
  List<int>? selectedTabs,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => UserProfileStore(usersRepository: users),
        ),
        ChangeNotifierProvider<TipsStore>(create: (_) => QuietTipsStore()),
        ChangeNotifierProvider<BadgesStore>(create: (_) => QuietBadgesStore()),
        ChangeNotifierProvider<LevelsStore>(create: (_) => QuietLevelsStore()),
        ChangeNotifierProvider<HunterBoardStore>(
          create: (_) => FixedBoardStore(board),
        ),
        ChangeNotifierProvider(create: (_) => HunterApplicationStore()),
        ChangeNotifierProvider(
          create: (_) =>
              UpdateReactionsStore(repository: FakeReactionsRepository()),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.bgBase,
        ),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(body: Text('route ${settings.name}')),
        ),
        home: Scaffold(
          body: MainTabScope(
            selectTab: (tab) => selectedTabs?.add(tab),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
