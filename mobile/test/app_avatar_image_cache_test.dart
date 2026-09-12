import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppAvatar is the most repeated remote image in the app. It used a raw
/// `Image.network`, which has no disk cache (every cold start re-downloads
/// each avatar) and no decode sizing, so a 1024px upload decoded to a ~4MB
/// bitmap on the UI isolate to fill a 32px circle. That decode is what made
/// the feed stutter while scrolling.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppAvatar remote images', () {
    testWidgets('caches to disk instead of using a raw Image.network',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppAvatar(
        radius: 16,
        imageUrl: 'https://example.com/avatar.png',
        fallback: Text('JD'),
      )));

      // CachedNetworkImage builds an Image internally, so the thing to assert
      // is that nothing reaches the network through an uncached NetworkImage
      // provider the way `Image.network` did.
      final uncached = tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => image.image is NetworkImage);
      expect(uncached, isEmpty);

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('decodes at display size rather than full resolution',
        (tester) async {
      const radius = 16.0;
      await tester.pumpWidget(_wrap(const AppAvatar(
        radius: radius,
        imageUrl: 'https://example.com/avatar.png',
        fallback: Text('JD'),
      )));

      final avatar = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final dpr = tester.view.devicePixelRatio;

      expect(avatar.memCacheWidth, (radius * 2 * dpr).round());
      expect(avatar.memCacheHeight, (radius * 2 * dpr).round());
    });

    testWidgets('a larger avatar asks for a proportionally larger decode',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppAvatar(
        radius: 48,
        imageUrl: 'https://example.com/avatar.png',
        fallback: Text('JD'),
      )));

      final large = tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .memCacheWidth;

      await tester.pumpWidget(_wrap(const AppAvatar(
        radius: 12,
        imageUrl: 'https://example.com/avatar.png',
        fallback: Text('JD'),
      )));

      final small = tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .memCacheWidth;

      expect(large, greaterThan(small!));
    });

    testWidgets('shows the fallback and fetches nothing without a url',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppAvatar(
        radius: 16,
        imageUrl: null,
        fallback: Text('JD'),
      )));

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('treats a whitespace-only url as no url', (tester) async {
      await tester.pumpWidget(_wrap(const AppAvatar(
        radius: 16,
        imageUrl: '   ',
        fallback: Text('JD'),
      )));

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('JD'), findsOneWidget);
    });
  });
}
