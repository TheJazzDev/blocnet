import 'package:blocnet/features/mining/data/mine_local_cache.dart';
import 'package:flutter/foundation.dart';

/// Open/closed state of the "How mining works" popover.
///
/// The popover is anchored to the `?` in the shared app bar while the
/// auto-open decision belongs to the Mine tab, so the two meet here rather
/// than through the widget tree.
class MineExplainer extends ChangeNotifier {
  MineExplainer._();

  static final MineExplainer instance = MineExplainer._();

  bool _isOpen = false;
  bool _autoChecked = false;

  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() => _isOpen ? close() : open();

  /// Opens the popover the first time this device shows the Mine tab, and
  /// remembers that it did. Nothing on the page moves.
  Future<void> autoOpenOnce(MineLocalCache cache) async {
    if (_autoChecked) return;
    _autoChecked = true;
    if (await cache.hasSeenExplainer()) return;
    await cache.markExplainerSeen();
    open();
  }

  @visibleForTesting
  void reset() {
    _isOpen = false;
    _autoChecked = false;
  }
}
