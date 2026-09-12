import 'package:blocnet/app/theme.dart';
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

    test('only high priority is raised off the feed ground', () {
      expect(FeedCardEmphasis.high.isRaised, isTrue);
      expect(FeedCardEmphasis.medium.isRaised, isFalse);
      expect(FeedCardEmphasis.low.isRaised, isFalse);
    });

    test('most of the feed carries no urgency edge at all', () {
      // This is what makes the other two legible. If low ever gains an edge,
      // every row shouts and none of them do.
      expect(FeedCardEmphasis.low.edgeColor, isNull);
      expect(FeedCardEmphasis.medium.edgeColor, isNotNull);
      expect(FeedCardEmphasis.high.edgeColor, isNotNull);
    });

    test('signal red is spent on high priority only', () {
      // Red is also the moderation and destructive colour, and a Ruby level
      // badge is red too. Keeping it off medium is what stops a card from
      // stacking three reds in one header line.
      expect(FeedCardEmphasis.high.edgeColor, AppColors.priorityHigh);
      expect(FeedCardEmphasis.medium.edgeColor, isNot(AppColors.priorityHigh));
    });

    test('the medium edge is darkened so it marks rather than warns', () {
      final edge = FeedCardEmphasis.medium.edgeColor!;
      expect(
        edge.computeLuminance(),
        lessThan(AppColors.priorityMid.computeLuminance()),
      );
    });
  });
}
