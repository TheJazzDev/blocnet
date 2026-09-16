import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';

/// The four physiques a gem row can take (design: "Row anatomy").
enum GemRowKind { current, due, quiet, neverUpdated }

/// The state chip a row carries.
enum GemChip { current, due, quiet }

/// One pip under the coverage figure.
enum CoveragePip { current, attention }

extension HunterBoardGemRow on HunterBoardGem {
  /// A never-updated gem always needs its hunter, whatever the clock says.
  /// An unknown state from a newer backend reads as current rather than as
  /// an alarm the platform cannot justify.
  GemRowKind get rowKind {
    if (neverUpdated) return GemRowKind.neverUpdated;
    switch (state) {
      case GemState.due:
        return GemRowKind.due;
      case GemState.quiet:
        return GemRowKind.quiet;
      case GemState.current:
      case GemState.unknown:
        return GemRowKind.current;
    }
  }

  bool get needsHunter => rowKind != GemRowKind.current;

  /// Quiet only when the backend says so; a never-updated gem otherwise
  /// reads as due (design: "due physique").
  GemChip get chip {
    switch (rowKind) {
      case GemRowKind.current:
        return GemChip.current;
      case GemRowKind.quiet:
        return GemChip.quiet;
      case GemRowKind.due:
        return GemChip.due;
      case GemRowKind.neverUpdated:
        return state == GemState.quiet ? GemChip.quiet : GemChip.due;
    }
  }

  /// When the gem was last touched: its newest update, else any activity.
  DateTime get lastTouchedAt => lastUpdate?.publishedAt ?? lastActivityAt;
}

/// Which parts of the Hub render, derived from the data alone. There is no
/// mode switch: day one, the attention rows, the fold and the reach row all
/// fall out of what the board holds.
class HubLayout {
  HubLayout({
    required this.board,
    required this.hasPendingAnswers,
    required this.now,
  })  : attention = board.gems.where((g) => g.needsHunter).toList(),
        current = board.gems.where((g) => !g.needsHunter).toList();

  /// Above this many current gems, they fold behind one line once anything
  /// needs the hunter (D3).
  static const int foldAbove = 3;

  final HunterBoard board;

  /// Pending invites or submissions in review.
  final bool hasPendingAnswers;
  final DateTime now;

  /// Gems that need the hunter, in the server's worst-first order.
  final List<HunterBoardGem> attention;
  final List<HunterBoardGem> current;

  HunterReliability get reliability => board.reliability;
  int get gemCount => board.gems.length;
  bool get isDayOne => board.gems.isEmpty;

  /// A hunter whose first gem is under two weeks old is not scored yet.
  bool get isUnscored =>
      !isDayOne && reliability.standing == ReliabilityStanding.newHunter;

  /// D3: current rows fold when something needs the hunter and more than
  /// [foldAbove] are current.
  bool get foldsCurrent => attention.isNotEmpty && current.length > foldAbove;

  /// D3: compact row copy goes with the fold.
  bool get compactCopy => foldsCurrent;

  /// Current rows listed under their own `CURRENT · N GEMS` header.
  bool get listsCurrentUnderHeader =>
      attention.isNotEmpty && current.isNotEmpty && !foldsCurrent;

  /// D6: reach is a receipt, shown only when nothing needs the hunter.
  bool get showsReach =>
      !isDayOne &&
      attention.isEmpty &&
      !hasPendingAnswers &&
      reliability.membersWaiting == 0 &&
      reliability.openReports == 0;

  /// D1: pips are current first, then every gem needing the hunter.
  List<CoveragePip> get pips => [
        for (final _ in current) CoveragePip.current,
        for (final _ in attention) CoveragePip.attention,
      ];

  /// The right-hand label on the `YOUR GEMS` header.
  String get gemsTrailing => attention.isNotEmpty
      ? '${attention.length} need you'
      : '${current.length} current';

  /// The fold line. "all posted this week" only when it is true.
  String get foldLabel {
    final weekAgo = now.subtract(const Duration(days: 7));
    final allThisWeek = current.every((g) => g.lastTouchedAt.isAfter(weekAgo));
    return allThisWeek
        ? '${current.length} current, all posted this week'
        : '${current.length} current';
  }
}
