import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:flutter/material.dart';

/// How much visual weight a feed card carries, derived from its update's
/// priority.
///
/// Round six of the home-feed design settled that **priority drives the whole
/// card, not a pill in its corner**: an urgent update keeps its place in the
/// chronological feed and simply becomes a heavier object, so a member feels
/// the difference while thumbing past instead of reading a label. Before this,
/// every card carried the same faint priority-tinted border and glow, which
/// meant a high-priority update looked almost exactly like a low one.
///
/// The mapping lives here rather than inline in the card so the rule is in one
/// place and can be asserted in a test.
///
/// Red is deliberately spent on one object only — the full-height left edge.
/// The design's own note: signal red stays on the edge and the priority pill,
/// identity red stays in a Ruby level badge, and the three are told apart by
/// scale and position rather than by hue.
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

  /// Urgent. Red edge, a ground warmed toward that red, and the title stepped
  /// up so the card reads as a bigger object from across the room.
  static final FeedCardEmphasis high = FeedCardEmphasis._(
    edgeColor: AppColors.priorityHigh,
    ground: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(AppColors.bgSurface, AppColors.priorityHigh, 0.10)!,
        Color.lerp(AppColors.bgBase, AppColors.priorityHigh, 0.06)!,
      ],
    ),
    titleSize: AppText.titleSize,
  );

  /// Worth knowing, not urgent. An amber edge dark enough that it reads as a
  /// marker rather than a warning, and no ground of its own.
  static final FeedCardEmphasis medium = FeedCardEmphasis._(
    edgeColor: Color.lerp(AppColors.priorityMid, AppColors.bgBase, 0.55),
    ground: null,
    titleSize: AppText.subtitleSize,
  );

  /// Most updates. No edge, no ground — a plain row separated from the next by
  /// a hairline. This is what makes the other two legible.
  static const FeedCardEmphasis low = FeedCardEmphasis._(
    edgeColor: null,
    ground: null,
    titleSize: AppText.bodySize,
  );
}
