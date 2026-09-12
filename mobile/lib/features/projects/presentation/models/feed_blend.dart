import 'package:blocnet/features/projects/data/models/update_model.dart';

/// How Home mixes updates from gems a member follows with curated ones from
/// gems they do not.
///
/// Round six of the home-feed design settled that Home never empties and never
/// becomes a different screen — the *proportion* of followed to curated posts
/// simply shifts as the member's board fills. A member who follows nothing gets
/// a browsable curated feed rather than an empty state, and a member who
/// follows ten gems sees almost only them.
///
/// This is deliberately a pure function over two lists so the rule can be
/// asserted in a test instead of being buried in a widget.
class FeedBlend {
  const FeedBlend._();

  /// Follows at which the feed is essentially all the member's own gems.
  ///
  /// Picked so the design's three checkpoints land: mostly curated at one gem,
  /// roughly half at three, almost entirely followed at ten.
  static const int saturationFollows = 6;

  /// The share of the feed that should come from followed gems, 0 to 1.
  static double followedShareFor(int followCount) {
    if (followCount <= 0) return 0;
    final share = followCount / saturationFollows;
    return share > 1 ? 1 : share;
  }

  /// How many curated posts to sit alongside [followedCount] followed ones to
  /// land near the target share. Zero once the member is saturated.
  static int curatedQuotaFor({
    required int followCount,
    required int followedCount,
  }) {
    if (followedCount <= 0) return _dayOneQuota;
    final share = followedShareFor(followCount);
    if (share >= 1) return _tailQuota;
    final total = followedCount / share;
    final quota = (total - followedCount).round();
    return quota < _tailQuota ? _tailQuota : quota;
  }

  /// Curated posts to show a member who follows nothing. Enough to be worth
  /// scrolling, which is the whole point of the day-one screen.
  static const int _dayOneQuota = 20;

  /// Even a saturated member gets a few, so the feed never dead-ends and
  /// there is always something new to follow.
  static const int _tailQuota = 3;

  /// Interleaves [followed] and [curated] so curated posts are spread through
  /// the feed rather than dumped at the end.
  ///
  /// [followed] must already be in the order the member should see it — this
  /// never reorders or drops a followed post, because hiding something someone
  /// explicitly asked to follow is never the right call. Curated posts are the
  /// only ones trimmed, down to the quota.
  static List<Update> blend({
    required List<Update> followed,
    required List<Update> curated,
    required int followCount,
  }) {
    if (followed.isEmpty) {
      return curated.take(_dayOneQuota).toList();
    }
    final quota = curatedQuotaFor(
      followCount: followCount,
      followedCount: followed.length,
    );
    final fill = curated.take(quota).toList();
    if (fill.isEmpty) return List<Update>.from(followed);

    // Walk both lists, emitting in proportion so the mix is even from the top
    // of the feed rather than front-loaded with one kind.
    final out = <Update>[];
    var f = 0;
    var c = 0;
    while (f < followed.length || c < fill.length) {
      final takeFollowed = c >= fill.length ||
          (f < followed.length && f * fill.length <= c * followed.length);
      if (takeFollowed) {
        out.add(followed[f++]);
      } else {
        out.add(fill[c++]);
      }
    }
    return out;
  }

  /// Which tab Home should open on, given how many gems are followed.
  ///
  /// The design's progression panel: *Following* becomes the default once the
  /// member has enough on their board for it to be worth reading.
  static bool defaultsToFollowing(int followCount) => followCount >= 3;
}
