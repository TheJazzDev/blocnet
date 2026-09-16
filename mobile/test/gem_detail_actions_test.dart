import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_header.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/share_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('share links open the gem path through blocnet.app', () {
    expect(
      blocnetShareLink('/projects/gem_1'),
      'https://blocnet.app/open?path=%2Fprojects%2Fgem_1',
    );
  });

  testWidgets('gem detail header offers share and no bookmark stub',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ProjectDetailsHeader(projectId: 'gem_1', title: 'Core Mines'),
      ),
    ));

    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
  });
}
