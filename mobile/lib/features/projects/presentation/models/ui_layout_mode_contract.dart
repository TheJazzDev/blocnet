import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';

abstract interface class UiLayoutModeContract {
  FeedViewMode get mode;
  Future<void> setMode(FeedViewMode nextMode);
}
