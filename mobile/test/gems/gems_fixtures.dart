import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wednesday 16 Sep 2026, 12:00.
final DateTime gemsNow = DateTime(2026, 9, 16, 12);

DateTime daysAgo(num days) =>
    gemsNow.subtract(Duration(minutes: (days * 24 * 60).round()));

Admin admin(String id, {String name = 'Ana Keeper', String? username}) => Admin(
      id: id,
      name: name,
      username: username ?? '@${id.replaceAll('-', '')}',
      imageUrl: '',
      followers: 10,
    );

Project gemProject(
  String id, {
  String name = 'Core Mines',
  String tag = 'Core',
  int followers = 12,
  int? updatesCount,
  Admin? owner,
  OwnerReliability? reliability,
  DateTime? lastUpdateAt,
  DateTime? createdAt,
  List<String> categories = const ['Airdrop'],
  String description = 'Mining and node rewards on Core.',
}) {
  return Project(
    id: id,
    logo: '',
    name: name,
    details: description,
    adminId: owner?.id ?? 'admin-1',
    admin: owner ?? admin('admin-1'),
    createdAt: createdAt ?? daysAgo(60),
    primaryTagId: 'tag-$tag',
    primaryTag: PrimaryTag(id: 'tag-$tag', name: tag),
    description: description,
    followersCount: followers,
    secondaryTags: [
      for (final c in categories) SecondaryTag(id: 'st-$c', name: c),
    ],
    updatesCount: updatesCount,
    ownerReliability: reliability,
    lastUpdateAt: lastUpdateAt,
  );
}

Update gemUpdate(
  String id,
  String projectId, {
  String title = 'KYC opened',
  required DateTime at,
  Priority? priority,
  DateTime? deadline,
}) {
  return Update(
    id: id,
    title: title,
    content: 'Body',
    description: 'Body',
    adminId: 'admin-1',
    projectId: projectId,
    priority: priority ?? Priority.mid,
    createdAt: at,
    deadlineAt: deadline,
    secondaryTagIds: const [],
    secondaryTags: const [],
  );
}

HunterReliability hunter(
  String id, {
  String name = 'Ana Keeper',
  String? username,
  ReliabilityStanding standing = ReliabilityStanding.reliable,
  double? coverage = 0.8,
  int gems = 5,
  int followers = 1204,
  int? answered = 4,
  int? asked = 5,
  double? cadence = 3,
}) {
  return HunterReliability(
    profileId: id,
    username: username ?? id.replaceAll('-', ''),
    displayName: name,
    standing: standing,
    coverage: coverage,
    gemsOwned: gems,
    updates30d: 4,
    followersTotal: followers,
    tipsReceivedTotal: BigInt.zero,
    membersWaiting: 0,
    openReports: 0,
    responseAnswered: answered,
    responseAsked: asked,
    response: answered == null || asked == null ? null : answered / asked,
    cadenceDays: cadence,
  );
}

HunterLeaderboardEntry ranked(int rank, HunterReliability r) =>
    HunterLeaderboardEntry(rank: rank, reliability: r);

GemListing listing(Project p, {List<Update> updates = const []}) {
  return GemListings.build(projects: [p], updates: updates, now: gemsNow)
      .single;
}

/// Records what a view asked for.
class ActionLog {
  final Set<String> followed = {};
  final List<String> calls = [];

  GemActions get actions => GemActions(
        isFollowed: followed.contains,
        onOpen: (g) => calls.add('open:${g.id}'),
        onToggleFollow: (g) => calls.add('follow:${g.id}'),
        onPreferences: (g) => calls.add('prefs:${g.id}'),
        onOpenKeeper: (GemKeeper k) => calls.add('keeper:${k.profileId}'),
        onAsk: (g) => calls.add('ask:${g.id}'),
      );
}

void usePhone(WidgetTester tester, {double width = 375, double height = 812}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget host(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
    ),
    home: Scaffold(body: child),
  );
}

Future<void> noRefresh() async {}

class FakeProjectsRepo extends ProjectsApiRepository {
  FakeProjectsRepo(this.projects, {this.fail = false});

  final List<Project> projects;
  final bool fail;

  @override
  Future<List<Project>> fetchProjects({int limit = 100, int offset = 0}) async {
    if (fail) throw Exception('offline');
    return projects;
  }

  @override
  Future<void> followProject(String projectId) async {}

  @override
  Future<void> unfollowProject(String projectId) async {}
}

class FakeUpdatesRepo extends UpdatesApiRepository {
  FakeUpdatesRepo(this.updates);

  final List<Update> updates;

  @override
  Future<List<Update>> fetchUpdates({
    int limit = 200,
    int offset = 0,
    String? projectId,
  }) async =>
      updates;
}

class FakeUsersRepo extends UsersApiRepository {
  FakeUsersRepo(this.followed);

  final List<String> followed;

  @override
  Future<Map<String, dynamic>?> fetchMe({bool forceRefresh = false}) async =>
      {'followedProjectIds': followed};
}
