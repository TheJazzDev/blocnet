import 'package:blocnet/features/auth/presentation/widgets/space_switcher.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/spaces_explainer_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RolesAuthStore extends AuthStore {
  _RolesAuthStore({this.hunter = false, this.moderation = false})
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  final bool hunter;
  final bool moderation;

  @override
  bool get hasHunterSpace => hunter;

  @override
  bool get hasModerationSpace => moderation;
}

Widget _wrap(AuthStore auth, Widget child) {
  return ChangeNotifierProvider<AuthStore>.value(
    value: auth,
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SpaceMeta', () {
    test('a plain user only has the User space', () {
      final spaces = SpaceMeta.availableFor(_RolesAuthStore());
      expect(spaces.map((s) => s.id), ['user']);
    });

    test('hunter and moderation roles add their spaces in order', () {
      final spaces = SpaceMeta.availableFor(
        _RolesAuthStore(hunter: true, moderation: true),
      );
      expect(spaces.map((s) => s.id), ['user', 'hunter', 'moderation']);
    });

    test('currentFor follows the active space', () {
      final auth = _RolesAuthStore(hunter: true);
      expect(SpaceMeta.currentFor(auth).id, 'user');
      auth.setActiveSpace('hunter');
      expect(SpaceMeta.currentFor(auth).id, 'hunter');
      expect(SpaceMeta.currentFor(auth).label, 'Hunter');
    });

    test('a space the user lacks cannot become current', () {
      final auth = _RolesAuthStore();
      auth.setActiveSpace('moderation');
      expect(SpaceMeta.currentFor(auth).id, 'user');
    });
  });

  group('SpaceSwitcher chip', () {
    testWidgets('renders nothing for a single-space user', (tester) async {
      await tester.pumpWidget(_wrap(_RolesAuthStore(), const SpaceSwitcher()));
      await tester.pump();

      expect(find.text('User'), findsNothing);
      expect(find.byIcon(Icons.public_rounded), findsNothing);
    });

    testWidgets('names the current space and opens the switcher sheet',
        (tester) async {
      final auth = _RolesAuthStore(hunter: true);
      await tester.pumpWidget(_wrap(auth, const SpaceSwitcher()));
      await tester.pump();

      expect(find.text('User'), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);

      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Space'), findsOneWidget);
      expect(find.text('Hunter'), findsOneWidget);
      expect(find.text('Moderation'), findsNothing);
    });
  });

  group('SpacesExplainerSheet', () {
    testWidgets('names each available space and what it is for',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpacesExplainerSheet(
              spaces: [SpaceMeta.user, SpaceMeta.hunter],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('You have two spaces'), findsOneWidget);
      expect(find.text('User space'), findsOneWidget);
      expect(find.text('Hunter space'), findsOneWidget);
      expect(find.textContaining('Post Updates'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    test('seen key is scoped per user', () {
      expect(
        SpacesExplainerSheet.seenKeyFor('abc'),
        isNot(SpacesExplainerSheet.seenKeyFor('xyz')),
      );
    });
  });
}
