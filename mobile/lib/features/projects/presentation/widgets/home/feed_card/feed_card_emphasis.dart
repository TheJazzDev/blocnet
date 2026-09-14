import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:flutter/material.dart';

/// How much visual weight a feed card carries, derived from its update's
/// priority.
///
/// Round six settled that priority drives the card rather than a pill in its
/// corner, and gave high priority a red left edge **and** a red-warmed ground.
/// That was drawn against a feed where one card in six was urgent.
///
/// **Revised 2026-09-14, on the owner's call, after seeing it on real data.**
/// Crypto updates are urgent far more often than the mock assumed, so the
/// ground turned long stretches of the feed red and scrolling became tiring —
/// at which point the signal stops being a signal. The edge and the ground are
/// both gone; the priority tag carries urgency now, with the title size still
/// stepping up so an urgent card is a visibly bigger object.
///
/// The mapping stays in this class precisely so this is one edit. If the feed
/// later proves too flat, restoring the edge is a one-line change here and
/// nothing else moves.
///
/// The mapping lives here rather than inline in the card so the rule is in one
/// place and can be asserted in a test.
@immutable
class FeedCardEmphasis {
  const FeedCardEmphasis._({
    required this.edgeColor,
    required this.ground,
    required this.titleSize,
  });

  /// Full-height 3px left edge. `null` when the card carries no urgency
  /// signal, which is most of the feed.
  final Color? edgeColor;

  /// The card's background. `null` keeps the feed's own ground, so an ordinary
  /// card is a row in a stream rather than a floating panel.
  final Gradient? ground;

  /// Size for the update title. The largest thing on the card at every
  /// urgency, and the thing that grows when it matters.
  final double titleSize;

  /// Whether this card is drawn as a distinct object rather than a plain row.
  bool get isRaised => ground != null;

  static FeedCardEmphasis of(Priority priority) {
    if (priority.isHigh) return high;
    if (priority.isMid) return medium;
    return low;
  }

  /// Urgent. The title steps up so the card is a visibly bigger object; the
  /// colour is spent on the priority tag alone.
  static const FeedCardEmphasis high = FeedCardEmphasis._(
    edgeColor: null,
    ground: null,
    titleSize: AppText.titleSize,
  );

  /// Worth knowing, not urgent.
  static const FeedCardEmphasis medium = FeedCardEmphasis._(
    edgeColor: null,
    ground: null,
    titleSize: AppText.subtitleSize,
  );

  /// Most updates. A plain row separated from the next by a hairline.
  static const FeedCardEmphasis low = FeedCardEmphasis._(
    edgeColor: null,
    ground: null,
    titleSize: AppText.bodySize,
  );
}
