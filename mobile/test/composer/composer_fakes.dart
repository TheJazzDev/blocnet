import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAuth extends AuthStore {
  FakeAuth({this.allowed = true})
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  final bool allowed;

  @override
  bool get canCreateUpdate => allowed;

  @override
  bool get canSubmitProject => allowed;

  @override
  bool get isInHunterSpace => false;

  @override
  bool get isHunter => false;
}

class FakeBoard extends HunterBoardStore {
  @override
  HunterBoard? get board => null;

  @override
  Future<void> loadBoard() async {}
}

class FakeProjects extends ProjectsStore {
  FakeProjects(this._list);

  final List<Project> _list;

  @override
  List<Project> get projects => _list;

  @override
  Future<void> fetchProjectsOnce() async {}

  @override
  Future<void> refreshProjects({bool forceRefresh = true}) async {}
}

class FakeTags extends TagsStore {
  FakeTags({
    this.primary = const [],
    this.secondary = const [],
    this.error,
  });

  List<PrimaryTag> primary;
  final List<SecondaryTag> secondary;
  String? error;
  int refreshes = 0;

  @override
  List<PrimaryTag> get primaryTags => primary;

  @override
  List<SecondaryTag> get secondaryTags => secondary;

  @override
  bool get isLoading => false;

  @override
  String? get lastError => error;

  @override
  Future<void> fetchOnce() async {}

  @override
  Future<void> refresh() async {
    refreshes++;
    notifyListeners();
  }
}

class FakeNotifications extends NotificationsStore {
  @override
  Future<void> refreshNotifications({String? category}) async {}
}

const String longName =
    'A Very Long Gem Name That Keeps Going Past The Edge Of A Small Phone';

Project longProject(String id) => Project(
      id: id,
      logo: '',
      name: longName,
      details: '',
      adminId: 'a',
      createdAt: DateTime(2026, 9, 1),
      primaryTagId: 't',
      primaryTag: const PrimaryTag(id: 't', name: 'Core'),
      description: '',
      followersCount: 0,
    );

final List<SecondaryTag> manyTags = [
  for (final n in [
    'Airdrop campaign with a long name',
    'Mining',
    'Launchpad',
    'Testnet',
    'Node sale',
  ])
    SecondaryTag(id: n, name: n),
];

void usePhone(WidgetTester tester, {double height = 812}) {
  tester.view.physicalSize = Size(375 * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps [screen] behind a launcher so it can pop.
Future<void> pumpBehindLauncher(
  WidgetTester tester,
  Widget screen, {
  required AuthStore auth,
  required TagsStore tags,
  List<Project> projects = const [],
}) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthStore>.value(value: auth),
      ChangeNotifierProvider<HunterBoardStore>.value(value: FakeBoard()),
      ChangeNotifierProvider<ProjectsStore>.value(
          value: FakeProjects(projects)),
      ChangeNotifierProvider<TagsStore>.value(value: tags),
      ChangeNotifierProvider<NotificationsStore>.value(
          value: FakeNotifications()),
      ChangeNotifierProvider<UpdatesStore>.value(value: UpdatesStore()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<Object?>(builder: (_) => screen)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
