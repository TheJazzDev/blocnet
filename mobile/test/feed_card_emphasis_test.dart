import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_emphasis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Priority identity', () {
    test('each level reports only itself', () {
      expect(Priority.high.isHigh, isTrue);
      expect(Priority.high.isMid, isFalse);
      expect(Priority.high.isLow, isFalse);

      expect(Priority.mid.isMid, isTrue);
      expect(Priority.mid.isHigh, isFalse);

      expect(Priority.low.isLow, isTrue);
      expect(Priority.low.isHigh, isFalse);
    });

    test('fromJson round-trips the three levels and defaults to low', () {
      expect(Priority.fromJson('high').isHigh, isTrue);
      expect(Priority.fromJson('medium').isMid, isTrue);
      expect(Priority.fromJson('mid').isMid, isTrue);
      expect(Priority.fromJson('low').isLow, isTrue);
      expect(Priority.fromJson('nonsense').isLow, isTrue);
    });
  });

  group('FeedCardEmphasis', () {
    test('maps each priority to its own treatment', () {
      expect(FeedCardEmphasis.of(Priority.high), same(FeedCardEmphasis.high));
      expect(FeedCardEmphasis.of(Priority.mid), same(FeedCardEmphasis.medium));
      expect(FeedCardEmphasis.of(Priority.low), same(FeedCardEmphasis.low));
    });

    test('title grows with urgency, so the card reads as a bigger object', () {
      expect(FeedCardEmphasis.high.titleSize, AppText.titleSize);
      expect(FeedCardEmphasis.medium.titleSize, AppText.subtitleSize);
      expect(FeedCardEmphasis.low.titleSize, AppText.bodySize);

      // The ordering is the point, not the specific values.
      expect(
        FeedCardEmphasis.high.titleSize,
        greaterThan(FeedCardEmphasis.medium.titleSize),
      );
      expect(
        FeedCardEmphasis.medium.titleSize,
        greaterThan(FeedCardEmphasis.low.titleSize),
      );
    });

    test('no card tints its ground or carries an urgency edge', () {
      // Decided 2026-09-14 after seeing it on real data: crypto updates are
      // urgent far more often than the mock assumed, so a red edge and a
      // red-warmed ground turned long stretches of the feed red and scrolling
      // became tiring. Colour now lives on the priority tag alone.
      //
      // If this ever regresses, the feed goes back to shouting on most rows.
      for (final e in [
        FeedCardEmphasis.high,
        FeedCardEmphasis.medium,
        FeedCardEmphasis.low,
      ]) {
        expect(e.edgeColor, isNull);
        expect(e.ground, isNull);
        expect(e.isRaised, isFalse);
      }
    });
  });
}
