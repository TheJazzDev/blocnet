import 'package:blocnet/features/gems/domain/gems_tab.dart';
import 'package:blocnet/features/gems/presentation/gems_navigation.dart';
import 'package:flutter/widgets.dart';

/// Opens the gems the member follows: Gems › Your board.
void openFollowedGems(BuildContext context) {
  GemsNavigation.open(context, tab: GemsTab.board);
}
