import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';

/// What the Gems views ask their host to do. The views hold no stores, so
/// every state can be pumped in a test.
class GemActions {
  const GemActions({
    required this.isFollowed,
    required this.onOpen,
    required this.onToggleFollow,
    required this.onPreferences,
    required this.onOpenKeeper,
    required this.onAsk,
  });

  final bool Function(String projectId) isFollowed;
  final void Function(GemListing gem) onOpen;
  final void Function(GemListing gem) onToggleFollow;
  final void Function(GemListing gem) onPreferences;
  final void Function(GemKeeper keeper) onOpenKeeper;

  /// Asks the gem's hunter for an update.
  final void Function(GemListing gem) onAsk;
}
