import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';

/// The line under the coverage figure. Coverage reads as a sentence, and a
/// slipping standing always names what to fix.
///
/// [gems] is the whole board in the server's worst-first order.
String coverageSentence(List<HunterBoardGem> gems) {
  final attention = gems.where((g) => g.needsHunter).toList();

  if (attention.isEmpty) {
    if (gems.length == 1) {
      return 'Your gem has an update from the last 14 days.';
    }
    if (gems.length == 2) {
      return 'Both gems have an update from the last 14 days.';
    }
    return 'Every gem you own has an update from the last 14 days.';
  }

  if (attention.length <= 2) {
    return attention.map(_nameGem).join(' ');
  }

  final quiet = attention.where((g) => g.chip == GemChip.quiet).length;
  final due = attention.length - quiet;
  final clauses = [
    if (quiet > 0) '${spelledCount(quiet)} quiet',
    if (due > 0) '${spelledCount(due)} due',
  ];
  final oldest = attention.reduce(
    (a, b) => b.daysQuiet > a.daysQuiet ? b : a,
  );
  return '${capitalized(clauses.join(', '))}. '
      '${oldest.name} is the oldest at ${_days(oldest.daysQuiet)}.';
}

String _nameGem(HunterBoardGem gem) {
  if (gem.chip == GemChip.quiet) {
    return '${gem.name} is quiet at ${_days(gem.daysQuiet)}.';
  }
  return '${gem.name} is due.';
}

String _days(int n) => counted(n, 'day');

/// The standing card's line before a hunter is scored.
const String unscoredSentence =
    'Coverage starts counting once your first gem is two weeks old.';

/// Day one adds why.
const String dayOneStandingSentence =
    'Coverage starts counting once your first gem is two weeks old. '
    'Nothing is scored before there is something to report.';
