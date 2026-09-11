import 'package:blocnet/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonList renders the requested number of cards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SkeletonList(items: 4, itemHeight: 60)),
      ),
    );

    expect(find.byType(SkeletonCard), findsNWidgets(4));
    expect(find.byType(SkeletonPulse), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // The pulse keeps animating; pumping a frame must not throw or settle.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SkeletonCard), findsNWidgets(4));
  });
}
