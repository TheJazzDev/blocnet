import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/hub_identity_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/hub_board_view.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hub_fixtures.dart';

/// The two phone widths every state is checked at.
const List<double> hubWidths = [375, 390];

/// Sets a phone-sized surface for one test.
void usePhone(WidgetTester tester, double width, {double height = 812}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget hostApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
    ),
    home: Scaffold(body: child),
  );
}

/// Records what the Hub asked its host to do.
class HubCalls {
  final List<String> opened = [];
  final List<String> posted = [];
  final List<String> responses = [];
  int submits = 0;

  HubBoardActions get actions => HubBoardActions(
        onOpenGem: (g) => opened.add(g.name),
        onPostUpdate: (g) => posted.add(g.name),
        onSubmitGem: () => submits++,
        onRespondToInvite: (invite, accept) =>
            responses.add('${invite.id}:$accept'),
        isResponding: (_) => false,
      );
}

HubIdentity identityFor(HunterBoard board) {
  final r = board.reliability;
  return HubIdentity(
    name: r.displayName!,
    handle: r.username,
    level: r.level?.level,
    levelName: r.level?.name,
  );
}

Future<HubCalls> pumpHub(
  WidgetTester tester,
  HunterBoard board, {
  double width = 375,
  List<ProjectInviteModel> invites = const [],
  List<ProjectProposalModel> proposals = const [],
}) async {
  usePhone(tester, width);
  final calls = HubCalls();
  await tester.pumpWidget(hostApp(HubBoardView(
    board: board,
    identity: identityFor(board),
    invites: invites,
    proposals: proposals,
    now: hubNow,
    actions: calls.actions,
    onRefresh: () async {},
  )));
  await tester.pump();
  return calls;
}

/// Asserts each finder's widget sits below the one before it.
void expectVerticalOrder(WidgetTester tester, List<Finder> finders) {
  double? last;
  for (final finder in finders) {
    expect(finder, findsOneWidget, reason: '$finder');
    final top = tester.getTopLeft(finder).dy;
    if (last != null) {
      expect(top, greaterThan(last), reason: '$finder should be below');
    }
    last = top;
  }
}

Finder byKey(String key) => find.byKey(ValueKey(key));

Finder rowOf(String projectId) => byKey('hub-row-$projectId');

Finder inside(Finder parent, Finder child) =>
    find.descendant(of: parent, matching: child);

Finder richText(String text) => find.text(text, findRichText: true);
