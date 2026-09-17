import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/gems/domain/gems_tab.dart';
import 'package:blocnet/features/gems/presentation/gems_navigation.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each Gems view and the old aliases open Gems on the right view', () {
    final routes = ProtectedRoutes.getAll();
    final expected = {
      AppRoutes.gems: GemsTab.discover,
      AppRoutes.discover: GemsTab.discover,
      AppRoutes.gemsBoard: GemsTab.board,
      AppRoutes.gemsHunters: GemsTab.hunters,
      AppRoutes.topHunters: GemsTab.hunters,
    };
    for (final entry in expected.entries) {
      expect(ProtectedRoutes.isProtectedRoute(entry.key), isTrue);
      final built = routes[entry.key]!(_FakeContext());
      expect(built, isA<GemsTabRedirect>(), reason: entry.key);
      expect((built as GemsTabRedirect).tab, entry.value, reason: entry.key);
    }
  });

  test('each view names its own route', () {
    expect(GemsTab.values.map((t) => t.route), [
      AppRoutes.gems,
      AppRoutes.gemsBoard,
      AppRoutes.gemsHunters,
    ]);
  });
}

class _FakeContext extends Fake implements BuildContext {}
