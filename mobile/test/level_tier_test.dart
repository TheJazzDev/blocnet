import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_number_format.dart';
import 'package:blocnet/features/levels/domain/level_requirement.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

UserLevelModel _level(int level, {String? color}) {
  return UserLevelModel(
    id: 'lvl-$level',
    slug: 'level-$level',
    name: 'Level $level',
    description: '',
    iconUrl: '',
    level: level,
    requiredBnp: '0',
    requiredComments: 0,
    requiredDaysActive: 0,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: color,
    isActive: true,
    sortOrder: level,
  );
}

void main() {
  group('LevelTier.forLevel', () {
    test('maps levels 1-15 to the five tiers in order', () {
      final names = [for (var n = 1; n <= 15; n++) LevelTier.forLevel(n).name];
      expect(names, [
        'Iron', 'Iron', 'Iron',
        'Jade', 'Jade', 'Jade',
        'Amethyst', 'Amethyst', 'Amethyst',
        'Gold', 'Gold', 'Gold',
        'Ruby', 'Ruby', 'Ruby',
      ]);
    });

    test('clamps out-of-range levels instead of throwing', () {
      expect(LevelTier.forLevel(0), LevelTier.iron);
      expect(LevelTier.forLevel(-5), LevelTier.iron);
      expect(LevelTier.forLevel(16), LevelTier.ruby);
      expect(LevelTier.forLevel(99), LevelTier.ruby);
    });

    test('exposes range labels and palette', () {
      expect(LevelTier.jade.rangeLabel, 'Levels 4–6');
      expect(LevelTier.gold.fallbackColor, const Color(0xFFF0B429));
      expect(LevelTier.all.map((t) => t.index), [0, 1, 2, 3, 4]);
      expect(LevelTier.amethyst.contains(8), isTrue);
      expect(LevelTier.amethyst.contains(10), isFalse);
    });
  });

  group('tier colour resolution', () {
    test('prefers the level colour when it parses', () {
      final level = _level(5, color: '#123456');
      expect(level.tierColor, const Color(0xFF123456));
    });

    test('falls back to the tier palette when colour is missing or bad', () {
      expect(_level(5).tierColor, LevelTier.jade.fallbackColor);
      expect(_level(5, color: 'lime').tierColor, LevelTier.jade.fallbackColor);
      expect(_level(14, color: '').tierColor, LevelTier.ruby.fallbackColor);
    });

    test('tryParseHexColor accepts 6 and 8 digit forms only', () {
      expect(tryParseHexColor('#E23D4A'), const Color(0xFFE23D4A));
      expect(tryParseHexColor('E23D4A'), const Color(0xFFE23D4A));
      expect(tryParseHexColor('80E23D4A'), const Color(0x80E23D4A));
      expect(tryParseHexColor('#FFF'), isNull);
      expect(tryParseHexColor(null), isNull);
    });

    test('foregroundOn picks dark text for gold and light for the rest', () {
      expect(foregroundOn(LevelTier.gold.fallbackColor), const Color(0xFF09090B));
      expect(foregroundOn(LevelTier.ruby.fallbackColor), const Color(0xFFFFFFFF));
      expect(foregroundOn(LevelTier.iron.fallbackColor), const Color(0xFFFFFFFF));
    });
  });

  group('groupLevelsByTier', () {
    test('produces five ordered sections of three for 15 shuffled levels', () {
      final levels = [for (var n = 15; n >= 1; n--) _level(n)];
      final sections = groupLevelsByTier(levels);

      expect(sections.length, 5);
      expect(sections.map((s) => s.tier), LevelTier.all);
      for (final section in sections) {
        expect(section.levels.length, 3);
        expect(
          section.levels.map((l) => l.level),
          [section.tier.minLevel, section.tier.minLevel + 1, section.tier.maxLevel],
        );
      }
    });

    test('omits tiers with no levels and keeps order', () {
      final sections = groupLevelsByTier([_level(13), _level(2), _level(7)]);
      expect(sections.map((s) => s.tier.name), ['Iron', 'Amethyst', 'Ruby']);
    });

    test('section colour comes from the first valid level colour', () {
      final sections = groupLevelsByTier([
        _level(4, color: 'bad'),
        _level(5, color: '#2AA876'),
        _level(6, color: '#000000'),
      ]);
      expect(sections.single.color, const Color(0xFF2AA876));
    });

    test('section colour falls back to the palette', () {
      final sections = groupLevelsByTier([_level(10), _level(11)]);
      expect(sections.single.color, LevelTier.gold.fallbackColor);
    });
  });

  group('requirementsFor', () {
    test('includes only non-zero criteria and compares raw values', () {
      const level = UserLevelModel(
        id: 'l',
        slug: 'l',
        name: 'L',
        description: '',
        iconUrl: '',
        level: 9,
        requiredBnp: '1500000',
        requiredComments: 0,
        requiredDaysActive: 30,
        requiredQuests: 5,
        requiredUpdates: 2,
        requiredProjects: 1,
        color: null,
        isActive: true,
        sortOrder: 9,
      );
      const metrics = UserMetrics(
        totalBnpEarned: '1499999',
        totalComments: 999,
        totalDaysActive: 30,
        totalQuestsCompleted: 7,
        totalUpdates: 1,
        totalProjects: 0,
      );

      final rows = requirementsFor(level, metrics: metrics);
      expect(rows.map((r) => r.metric), [
        LevelMetric.bnp,
        LevelMetric.daysActive,
        LevelMetric.quests,
        LevelMetric.updates,
        LevelMetric.projects,
      ]);

      final bnp = rows.first;
      expect(bnp.isComplete, isFalse);
      expect(bnp.remaining, BigInt.one);
      expect(bnp.currentLabel, '1.4M');
      expect(bnp.requiredLabel, '1.5M');

      expect(rows[1].isComplete, isTrue); // days active 30/30
      expect(rows[2].isComplete, isTrue); // quests 7/5
      expect(rows[3].isComplete, isFalse); // updates 1/2
      expect(rows[4].remaining, BigInt.one); // projects 0/1
    });

    test('treats missing metrics as zero', () {
      final rows = requirementsFor(_level(1), metrics: null);
      expect(rows, isEmpty);
    });
  });

  group('number formatting', () {
    test('formatCompact', () {
      expect(formatCompact(BigInt.from(999)), '999');
      expect(formatCompact(BigInt.from(1000)), '1K');
      expect(formatCompact(BigInt.from(12500)), '12.5K');
      expect(formatCompact(BigInt.from(2000000)), '2M');
      expect(formatCompact(BigInt.parse('12345678901234')), '12345678.9M');
    });

    test('parseBigInt tolerates commas, decimals and junk', () {
      expect(parseBigInt('1,234'), BigInt.from(1234));
      expect(parseBigInt('12.9'), BigInt.from(12));
      expect(parseBigInt('abc'), BigInt.zero);
      expect(parseBigInt(null), BigInt.zero);
    });
  });
}
