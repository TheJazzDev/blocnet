import 'package:blocnet/constants/app_routes.dart';

/// The three views of the Gems bottom tab.
enum GemsTab {
  discover('Discover', AppRoutes.gems),
  board('Your board', AppRoutes.gemsBoard),
  hunters('Hunters', AppRoutes.gemsHunters);

  const GemsTab(this.label, this.route);

  final String label;

  /// The named route that opens Gems on this view.
  final String route;
}
