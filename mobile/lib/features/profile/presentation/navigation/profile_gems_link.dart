import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:flutter/widgets.dart';

/// Opens the gems the member follows. Profile's single way there.
///
/// Followed gems live in Gems › Your board. Until the Gems tab can be opened
/// on a sub-tab, this lands on the Gems tab itself; point it at "Your board"
/// here, and only here, once that API exists.
void openFollowedGems(BuildContext context) {
  MainTabNavigator.open(
    context,
    MainTabScope.discoverTab,
    fallbackRoute: AppRoutes.discover,
  );
}
