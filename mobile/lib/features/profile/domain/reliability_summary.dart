import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';

/// How a standing is drawn on Profile.
enum StandingTone { reliable, slipping, unscored }

/// A hunter's reliability in one line: a standing word and a count.
class ReliabilitySummary {
  const ReliabilitySummary({
    required this.standing,
    required this.tone,
    required this.detail,
  });

  /// `Reliable`, `Slipping`, `Quiet` or `New`.
  final String standing;
  final StandingTone tone;

  /// `4 of 5 gems current`, `No gems yet`, `5 gems`.
  final String detail;

  /// From the signed-in hunter's own board, with the Hub's rules: the
  /// standing is the server's, the count is current gems only.
  factory ReliabilitySummary.fromBoard(HunterBoard board) {
    final gems = board.gems;
    if (gems.isEmpty) {
      return const ReliabilitySummary(
        standing: 'New',
        tone: StandingTone.unscored,
        detail: 'No gems yet',
      );
    }
    final current = gems.where((g) => !g.needsHunter).length;
    final standing = board.reliability.standing;
    if (standing == ReliabilityStanding.newHunter) {
      return ReliabilitySummary(
        standing: 'New',
        tone: StandingTone.unscored,
        detail: _gems(gems.length),
      );
    }
    final slipping = switch (standing) {
      ReliabilityStanding.reliable => false,
      ReliabilityStanding.slipping || ReliabilityStanding.quiet => true,
      _ => current < gems.length,
    };
    final word = standing == ReliabilityStanding.unknown
        ? (slipping ? 'Slipping' : 'Reliable')
        : standing.label;
    return ReliabilitySummary(
      standing: word,
      tone: slipping ? StandingTone.slipping : StandingTone.reliable,
      detail: '$current of ${gems.length} gems current',
    );
  }

  /// From another hunter's public reliability, which has coverage but no
  /// gem list.
  factory ReliabilitySummary.fromReliability(HunterReliability r) {
    final owned = r.gemsOwned;
    if (owned == 0) {
      return const ReliabilitySummary(
        standing: 'New',
        tone: StandingTone.unscored,
        detail: 'No gems yet',
      );
    }
    final coverage = r.coverage;
    switch (r.standing) {
      case ReliabilityStanding.newHunter:
      case ReliabilityStanding.unknown:
        return ReliabilitySummary(
          standing: 'New',
          tone: StandingTone.unscored,
          detail: _gems(owned),
        );
      case ReliabilityStanding.reliable:
      case ReliabilityStanding.slipping:
      case ReliabilityStanding.quiet:
        final current = coverage == null ? null : (coverage * owned).round();
        return ReliabilitySummary(
          standing: r.standing.label,
          tone: r.standing == ReliabilityStanding.reliable
              ? StandingTone.reliable
              : StandingTone.slipping,
          detail: current == null
              ? _gems(owned)
              : '$current of $owned gems current',
        );
    }
  }

  static String _gems(int n) => n == 1 ? '1 gem' : '$n gems';
}
