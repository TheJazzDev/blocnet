import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/blocnet_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every gem and update result in global search must open something.
void main() {
  final project = Project(
    id: 'project-1',
    logo: '',
    name: 'Core Mines',
    details: 'Mining on Core',
    adminId: 'author-1',
    createdAt: DateTime(2026, 9, 1),
    primaryTagId: 'tag-1',
    primaryTag: const PrimaryTag(id: 'tag-1', name: 'Core', slug: 'core'),
    description: 'Mining and node operation opportunities on Core',
    followersCount: 3,
  );
  final update = Update(
    id: 'update-1',
    title: 'KYC opens for Phase 2',
    content: 'Use the same wallet you mined with.',
    description: 'Use the same wallet you mined with.',
    adminId: 'author-1',
    projectId: 'project-1',
    priority: Priority.high,
    createdAt: DateTime(2026, 9, 12),
    secondaryTagIds: const [],
    secondaryTags: const [],
    project: project,
  );

  testWidgets('gem and update results are tappable', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showSearch(
            context: context,
            delegate: BlocnetSearchDelegate(
              projects: [project],
              posts: [update],
            ),
          ),
          child: const Text('search'),
        ),
      ),
    ));
    await tester.tap(find.text('search'));
    await tester.pumpAndSettle();

    // The gem name is also each update's subtitle; the gem row comes first.
    ListTile tileFor(String title) => tester.widget<ListTile>(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(ListTile),
          ).first,
        );

    expect(tileFor('Core Mines').onTap, isNotNull);
    expect(tileFor('KYC opens for Phase 2').onTap, isNotNull);
  });
}
