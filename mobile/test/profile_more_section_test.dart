import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_content_section.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/profile_more_section.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RolesAuthStore extends AuthStore {
  _RolesAuthStore({this.hunter = false, this.ownerOrDev = false})
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  final bool hunter;
  final bool ownerOrDev;

  @override
  bool get hasHunterSpace => hunter || ownerOrDev;

  @override
  bool get isOwner => ownerOrDev;
}

Future<void> _pump(WidgetTester tester, AuthStore auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>.value(value: auth),
        ChangeNotifierProvider(create: (_) => FeedViewModeStore()),
        ChangeNotifierProvider(create: (_) => HunterApplicationStore()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (auth.hasHunterSpace) const HunterContentSection(),
                ProfileMoreSection(auth: auth, onSignOut: () {}),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('everyone sees badges, quests, levels, tips, referral, settings, '
      'help and sign out', (tester) async {
    await _pump(tester, _RolesAuthStore());

    for (final title in [
      'Badges',
      'Quests',
      'Levels',
      'Tip History',
      'Referral Code',
      'Settings',
      'Help & Support',
      'Sign Out',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Tip History (Received)'), findsNothing);
    expect(find.text('System Alerts'), findsNothing);
    expect(find.text('Manage My Gems'), findsNothing);
    // Non-hunters get the entry point into the hunter path.
    expect(find.text('Become a Hunter'), findsOneWidget);
  });

  testWidgets('hunters additionally see content shortcuts and received tips',
      (tester) async {
    await _pump(tester, _RolesAuthStore(hunter: true));

    expect(find.text('Submit New Gem'), findsOneWidget);
    expect(find.text('Manage My Gems'), findsOneWidget);
    expect(find.text('Manage My Updates'), findsOneWidget);
    expect(find.text('Tip History (Received)'), findsOneWidget);
    // Nothing from the shared list goes away for hunters.
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Quests'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('System Alerts'), findsNothing);
    expect(find.text('Become a Hunter'), findsNothing);
  });

  testWidgets('system alerts stay owner/dev only', (tester) async {
    await _pump(tester, _RolesAuthStore(ownerOrDev: true));

    expect(find.text('System Alerts'), findsOneWidget);
  });
}
