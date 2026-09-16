import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_day_one.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The day-one rail used to swallow taps (`onOpen: (_) {}`). Tapping a
/// hunter must hand back that hunter, so Home can open their profile.
void main() {
  testWidgets('tapping a hunter opens that hunter', (tester) async {
    Admin hunter(String id, String username) => Admin(
          id: id,
          name: username,
          username: username,
          imageUrl: '',
          followers: 0,
          roles: const ['hunter'],
        );
    final ada = hunter('h1', 'ada');
    final bo = hunter('h2', 'bo');
    final opened = <Admin>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedTopHunters(
            hunters: [
              (handle: '@ada', name: 'ada', admin: ada),
              (handle: '@bo', name: 'bo', admin: bo),
            ],
            onOpen: opened.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('@bo'));
    expect(opened, [bo]);
  });
}
