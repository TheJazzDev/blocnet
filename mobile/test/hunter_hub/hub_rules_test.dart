import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/chain_style.dart';
import 'package:blocnet/features/hunter/domain/coverage_sentence.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hub_fixtures.dart';

HubLayout _layout(HunterBoard board, {bool answers = false}) =>
    HubLayout(board: board, hasPendingAnswers: answers, now: hubNow);

void main() {
  group('ChainStyle', () {
    test('maps each chain in the spec table to its label and colour', () {
      final cases = {
        'Core': ('CORE', AppColors.chainCore),
        'Telegram Network': ('TELEGRAM', AppColors.chainTelegram),
        'Solana': ('SOLANA', AppColors.chainSolana),
        'Ethereum': ('ETHEREUM', AppColors.chainEthereum),
        'Binance Smart Chain': ('BSC', AppColors.chainBsc),
        'BSC': ('BSC', AppColors.chainBsc),
        'Ice Open Network': ('ICE', AppColors.chainIce),
      };
      cases.forEach((tag, expected) {
        final style = ChainStyle.forTag(tag);
        expect(style.label, expected.$1, reason: tag);
        expect(style.color, expected.$2, reason: tag);
        expect(style.chipBackground, expected.$2.withValues(alpha: 0.12));
        expect(style.gradient.first, expected.$2);
      });
    });

    test('an unknown tag keeps its name on a neutral chip', () {
      final style = ChainStyle.forTag('DeFi');
      expect(style.label, 'DEFI');
      expect(style.color, AppColors.textMuted);
      expect(style.chipBackground, AppColors.bgElevated);
      expect(ChainStyle.forTag('').label, '');
    });

    test('monograms take two initials, or two letters of one word', () {
      expect(gemMonogram('Core Mines'), 'CM');
      expect(gemMonogram('Bless50ing'), 'B5');
      expect(gemMonogram('x'), 'X');
      expect(gemMonogram('  '), '?');
    });
  });

  group('coverageSentence', () {
    test('all current reads by gem count', () {
      expect(coverageSentence([coreMines()]),
          'Your gem has an update from the last 14 days.');
      expect(coverageSentence(invitesBoard().gems),
          'Both gems have an update from the last 14 days.');
      expect(coverageSentence(allCurrentBoard().gems),
          'Every gem you own has an update from the last 14 days.');
    });

    test('one or two gems needing the hunter are each named', () {
      expect(coverageSentence(slippingBoard().gems),
          'Halo Points is quiet at 19 days. Terra Vault is due.');
      expect(
          coverageSentence([terraVault(), coreMines()]), 'Terra Vault is due.');
    });

    test('three or more are counted, with the oldest named', () {
      expect(coverageSentence(dozenBoard().gems),
          'Two quiet, one due. Aegis Node is the oldest at 21 days.');
    });

    test('a zero clause is omitted and counts past ten stay digits', () {
      final dues = [
        for (var i = 0; i < 11; i++)
          gem('Due $i', state: GemState.due, daysQuiet: 10 + i),
      ];
      expect(
          coverageSentence(dues), '11 due. Due 10 is the oldest at 20 days.');
      final quiets = [haloPoints(), aegisNode(), haloPoints()];
      expect(coverageSentence(quiets),
          'Three quiet. Aegis Node is the oldest at 21 days.');
    });

    test('a never-updated gem reads as due unless the server says quiet', () {
      expect(coverageSentence([prismYield()]), 'Prism Yield is due.');
    });
  });

  group('HubLayout', () {
    test('state 1: nothing needs the hunter, so reach shows and no fold', () {
      final layout = _layout(allCurrentBoard());
      expect(layout.attention, isEmpty);
      expect(layout.current.length, 5);
      expect(layout.foldsCurrent, isFalse);
      expect(layout.listsCurrentUnderHeader, isFalse);
      expect(layout.showsReach, isTrue);
      expect(layout.gemsTrailing, '5 current');
      expect(layout.pips, List.filled(5, CoveragePip.current));
    });

    test('state 2: three current list under a header, no fold (D3)', () {
      final layout = _layout(slippingBoard());
      expect(
          layout.attention.map((g) => g.name), ['Halo Points', 'Terra Vault']);
      expect(layout.foldsCurrent, isFalse);
      expect(layout.compactCopy, isFalse);
      expect(layout.listsCurrentUnderHeader, isTrue);
      expect(layout.showsReach, isFalse);
      expect(layout.gemsTrailing, '2 need you');
      expect(layout.pips, [
        ...List.filled(3, CoveragePip.current),
        ...List.filled(2, CoveragePip.attention),
      ]);
    });

    test('state 5: more than three current fold, with compact copy', () {
      final layout = _layout(dozenBoard());
      expect(layout.foldsCurrent, isTrue);
      expect(layout.compactCopy, isTrue);
      expect(layout.listsCurrentUnderHeader, isFalse);
      expect(layout.gemsTrailing, '3 need you');
      expect(layout.current.length, 9, reason: 'D1 counts current only');
      expect(layout.foldLabel, '9 current, all posted this week');
    });

    test('the fold only claims "this week" when it is true', () {
      final board = HunterBoard(
        reliability: reliability(),
        gems: [
          haloPoints(),
          for (var i = 0; i < 4; i++) gem('Old $i', ago: Duration(days: 8 + i)),
        ],
      );
      expect(_layout(board).foldLabel, '4 current');
    });

    test('state 4: pending answers hide reach even when all current', () {
      expect(_layout(invitesBoard(), answers: true).showsReach, isFalse);
      expect(_layout(invitesBoard()).showsReach, isTrue);
    });

    test('state 3: no gems is day one and never shows reach', () {
      final layout = _layout(dayOneBoard());
      expect(layout.isDayOne, isTrue);
      expect(layout.showsReach, isFalse);
      expect(layout.isUnscored, isFalse);
    });

    test('waiting members alone hide reach', () {
      final board = HunterBoard(
        reliability: reliability(waiting: 3),
        gems: [coreMines()],
      );
      expect(_layout(board).showsReach, isFalse);
    });

    test('a never-updated gem needs the hunter with a due chip', () {
      final g = prismYield();
      expect(g.neverUpdated, isTrue);
      expect(g.rowKind, GemRowKind.neverUpdated);
      expect(g.chip, GemChip.due);
      expect(g.needsHunter, isTrue);
    });
  });

  group('hub_format', () {
    test('states amounts and times plainly', () {
      expect(groupedCount(26465), '26,465');
      expect(counted(1, 'member'), '1 member');
      expect(counted(31, 'member'), '31 members');
      expect(shortAgo(hubNow.subtract(const Duration(hours: 3)), hubNow),
          '3h ago');
      expect(
          shortAgo(hubNow.subtract(const Duration(days: 2)), hubNow), '2d ago');
      expect(daysAgo(0), 'today');
      expect(daysAgo(1), '1 day ago');
      expect(formatTips(bnp(18240), 'BNP', 18), '18,240 BNP');
      expect(formatTips(BigInt.zero, 'BNP', 18), isNull);
      expect(formatAtomic(BigInt.from(1500), 3), '1.5');
      expect(dayMonth(DateTime(2026, 8, 20)), '20 Aug');
      expect(urgencyLabel('mid'), 'Medium');
      expect(spelledCount(10), 'ten');
      expect(spelledCount(12), '12');
    });
  });
}
