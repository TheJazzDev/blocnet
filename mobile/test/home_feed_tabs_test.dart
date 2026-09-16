import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_tab_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Home has two tabs, Following then For you. General was cut (APP_MAP §3);
/// "everything, newest first" moves to Gems.
void main() {
  testWidgets('Home renders exactly two tabs: Following, then For you',
      (tester) async {
    final auth = AuthStore(
      enableSupabaseAuthListener: false,
      supabaseConfiguredOverride: false,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthStore>.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(
            body: FeedTabBar(
              activeSection: Sections.forYou,
              onTabChanged: (_) {},
              dimFollowing: false,
            ),
          ),
        ),
      ),
    );

    final tabs = tester
        .widgetList<FeedTabItem>(find.byType(FeedTabItem))
        .map((tab) => tab.label)
        .toList();
    expect(tabs, ['Following', 'For you']);
    expect(find.text('General'), findsNothing);
  });
}
