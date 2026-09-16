import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/pages/create_update_args.dart';
import 'package:blocnet/features/projects/presentation/pages/create_update_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'hub_fixtures.dart';
import 'hub_harness.dart';

class _Auth extends AuthStore {
  _Auth()
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  @override
  bool get canCreateUpdate => true;

  @override
  bool get isInHunterSpace => true;
}

class _Board extends HunterBoardStore {
  @override
  HunterBoard? get board => slippingBoard();

  @override
  Future<void> loadBoard() async {}
}

class _Projects extends ProjectsStore {
  @override
  Future<void> fetchProjectsOnce() async {}

  @override
  Future<void> refreshProjects({bool forceRefresh = true}) async {}
}

class _Tags extends TagsStore {
  @override
  Future<void> fetchOnce() async {}
}

class _Notifications extends NotificationsStore {
  @override
  Future<void> refreshNotifications({String? category}) async {}
}

class _Updates extends UpdatesStore {
  final List<Update> patched = [];

  @override
  Future<Update?> loadUpdate(String id) async => Update(
        id: id,
        title: 'Farming round 2 is live',
        content: 'Deposit before the cap fills, round two.',
        adminId: 'me',
        priority: Priority.high,
        createdAt: DateTime(2026, 8, 20),
        projectId: 'p-halo-points',
        description: '',
        deadlineAt: fridayEvening,
        secondaryTagIds: const ['t1'],
        secondaryTags: const [SecondaryTag(id: 't1', name: 'Farming')],
      );

  @override
  Future<void> updateUpdate(Update updatedUpdate) async =>
      patched.add(updatedUpdate);

  @override
  Future<void> refreshUpdates() async {}
}

Future<_Updates> _pumpComposer(
  WidgetTester tester,
  CreateUpdateArgs args,
) async {
  usePhone(tester, 375, height: 1400);
  final updates = _Updates();
  final results = <Object?>[];
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthStore>.value(value: _Auth()),
      ChangeNotifierProvider<HunterBoardStore>.value(value: _Board()),
      ChangeNotifierProvider<ProjectsStore>.value(value: _Projects()),
      ChangeNotifierProvider<TagsStore>.value(value: _Tags()),
      ChangeNotifierProvider<NotificationsStore>.value(value: _Notifications()),
      ChangeNotifierProvider<UpdatesStore>.value(value: updates),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CreateUpdateScreen(
                projectId: args.projectId,
                updateId: args.updateId,
              ),
            )));
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  addTearDown(() => expect(results, anyOf(isEmpty, [true])));
  return updates;
}

void main() {
  test('route arguments read from the object or a plain map', () {
    expect(CreateUpdateArgs.from(null).isEdit, isFalse);
    final fromMap = CreateUpdateArgs.from({'projectId': 'p', 'updateId': 'u'});
    expect(fromMap.projectId, 'p');
    expect(fromMap.isEdit, isTrue);
    expect(CreateUpdateArgs.from({'updateId': ' '}).isEdit, isFalse);
  });

  testWidgets('a gem opened from the Hub is pre-selected, board gems first',
      (tester) async {
    await _pumpComposer(
        tester, const CreateUpdateArgs(projectId: 'p-terra-vault'));
    expect(tester.takeException(), isNull);
    expect(find.text('Create Update'), findsOneWidget);
    // The selected value shows in the field.
    expect(find.text('Terra Vault'), findsOneWidget);
    expect(find.text('DUE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('composer-project')));
    await tester.pumpAndSettle();
    final names = ['Halo Points', 'Terra Vault', 'Core Mines'];
    double? last;
    for (final name in names) {
      final y = tester.getTopLeft(find.text(name).last).dy;
      if (last != null) expect(y, greaterThan(last));
      last = y;
    }
    expect(find.text('QUIET'), findsWidgets);
    expect(find.text('CURRENT'), findsWidgets);
  });

  testWidgets('edit mode prefills and saves as a patch', (tester) async {
    final updates = await _pumpComposer(
      tester,
      const CreateUpdateArgs(projectId: 'p-halo-points', updateId: 'u-1'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Edit update'), findsOneWidget);
    expect(find.text('Farming round 2 is live'), findsOneWidget);
    expect(
        find.text('Deposit before the cap fills, round two.'), findsOneWidget);
    expect(find.text('High Urgency'), findsOneWidget);
    expect(find.text('Halo Points'), findsOneWidget);
    expect(find.text('No closing window'), findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('composer-title')), 'Farming round 2 closes');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final patched = updates.patched.single;
    expect(patched.id, 'u-1');
    expect(patched.title, 'Farming round 2 closes');
    expect(patched.priority, Priority.high);
    expect(patched.deadlineAt, fridayEvening);
    expect(patched.secondaryTagIds, ['t1']);
    expect(find.text('Edit update'), findsNothing, reason: 'popped');
  });
}
