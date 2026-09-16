import 'package:blocnet/features/profile/presentation/widgets/activity_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_recent_activity.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a tappable activity row shows a chevron and ripples',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(ActivityCard(
      title: 'KYC opens',
      subtitle: 'Core Mines',
      time: '2h',
      onTap: () => taps++,
    )));

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.text('KYC opens'));
    expect(taps, 1);
  });

  testWidgets('an activity row with nothing to open looks inert',
      (tester) async {
    await tester.pumpWidget(_host(const ActivityCard(
      title: 'KYC opens',
      subtitle: 'Core Mines',
      time: '2h',
    )));

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('recent activity rows for updates are tappable',
      (tester) async {
    final update = Update(
      id: 'update-1',
      title: 'KYC opens for Phase 2',
      content: 'Body',
      description: 'Body',
      adminId: 'author-1',
      projectId: 'project-1',
      priority: Priority.high,
      createdAt: DateTime(2026, 9, 12),
      secondaryTagIds: const [],
      secondaryTags: const [],
    );
    await tester.pumpWidget(
      _host(PublicProfileRecentActivity(posts: [update])),
    );

    final card = tester.widget<ActivityCard>(find.byType(ActivityCard));
    expect(card.onTap, isNotNull);
  });
}
