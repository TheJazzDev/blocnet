import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter_test/flutter_test.dart';

// A Saturday afternoon, so weekday and tonight cases are both reachable.
final now = DateTime(2026, 9, 12, 14, 0);

void main() {
  group('describeDeadline', () {
    test('states a time, and never counts down to one', () {
      // The whole point of round six's change. If any of these ever start
      // reading "in 6h 12m", the clock has come back.
      final samples = [
        DateTime(2026, 9, 12, 22, 0),
        DateTime(2026, 9, 13, 9, 0),
        DateTime(2026, 9, 16, 18, 0),
        DateTime(2026, 10, 30, 12, 0),
        DateTime(2026, 9, 1, 12, 0),
      ];
      for (final at in samples) {
        final label = describeDeadline(at, now).label;
        expect(label, isNot(contains(' in ')), reason: label);
        expect(label, isNot(matches(RegExp(r'\d+[hm]\b'))), reason: label);
      }
    });

    test('closing this evening is the one case allowed emphasis', () {
      final p = describeDeadline(DateTime(2026, 9, 12, 22, 0), now);
      expect(p.label, 'Closes tonight');
      expect(p.isToday, isTrue);
      expect(p.hasPassed, isFalse);
    });

    test('closing earlier today names the hour instead of saying tonight', () {
      final p = describeDeadline(DateTime(2026, 9, 12, 16, 30), now);
      expect(p.label, 'Closes today, 4:30pm');
      expect(p.isToday, isTrue);
    });

    test('tomorrow is named rather than dated', () {
      final p = describeDeadline(DateTime(2026, 9, 13, 9, 0), now);
      expect(p.label, 'Closes tomorrow, 9am');
      expect(p.isToday, isFalse);
    });

    test('inside a week uses the weekday, the way a hunter would say it', () {
      final p = describeDeadline(DateTime(2026, 9, 16, 18, 0), now);
      expect(p.label, 'Closes Wednesday, 6pm');
    });

    test('further out falls back to a date', () {
      final p = describeDeadline(DateTime(2026, 10, 30, 12, 0), now);
      expect(p.label, 'Closes 30 Oct');
    });

    test('a passed window is stated, not hidden', () {
      // The design shows this explicitly. A hunter may report a window that has
      // already shut, and pretending it never existed helps nobody.
      final p = describeDeadline(DateTime(2026, 9, 3, 12, 0), now);
      expect(p.label, 'Window closed 9 days ago');
      expect(p.hasPassed, isTrue);
      expect(p.isToday, isFalse);
    });

    test('a long-passed window rounds to weeks rather than counting days', () {
      final p = describeDeadline(DateTime(2026, 8, 1, 12, 0), now);
      expect(p.label, 'Window closed 6 weeks ago');
      expect(p.hasPassed, isTrue);
    });

    test('a window that shut hours ago says hours', () {
      final p = describeDeadline(DateTime(2026, 9, 12, 9, 0), now);
      expect(p.label, 'Window closed 5 hours ago');
    });

    test('singular and plural agree', () {
      expect(
        describeDeadline(DateTime(2026, 9, 11, 13, 0), now).label,
        'Window closed 1 day ago',
      );
      expect(
        describeDeadline(DateTime(2026, 9, 12, 13, 0), now).label,
        'Window closed 1 hour ago',
      );
    });

    test('midday and midnight read as 12, not 0', () {
      expect(
        describeDeadline(DateTime(2026, 9, 13, 12, 0), now).label,
        'Closes tomorrow, 12pm',
      );
      expect(
        describeDeadline(DateTime(2026, 9, 13, 0, 30), now).label,
        'Closes tomorrow, 12:30am',
      );
    });
  });
}
