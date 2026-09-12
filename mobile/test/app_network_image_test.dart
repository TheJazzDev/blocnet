import 'package:blocnet/shared/widgets/app_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared remote-image widget. Project logos were each calling
/// `Image.network` directly, so none of them cached to disk or sized their
/// decode; this puts that in one place.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _url = 'https://example.com/logo.png';

void main() {
  group('AppNetworkImage', () {
    testWidgets('loads through the disk cache, not a raw NetworkImage',
        (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 40,
        height: 40,
        child: AppNetworkImage(url: _url, fallback: Icon(Icons.layers)),
      )));

      final uncached = tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => image.image is NetworkImage);
      expect(uncached, isEmpty);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('sizes the decode from an explicit width and height',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppNetworkImage(
        url: _url,
        width: 40,
        height: 40,
        fallback: Icon(Icons.layers),
      )));

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final dpr = tester.view.devicePixelRatio;

      expect(image.memCacheWidth, (40 * dpr).round());
      expect(image.memCacheHeight, (40 * dpr).round());
    });

    testWidgets('falls back to layout constraints when no size is given',
        (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 64,
        height: 64,
        child: AppNetworkImage(url: _url, fallback: Icon(Icons.layers)),
      )));

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final dpr = tester.view.devicePixelRatio;

      expect(image.memCacheWidth, (64 * dpr).round());
    });

    testWidgets('still bounds the decode under unbounded constraints',
        (tester) async {
      await tester.pumpWidget(_wrap(SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: const SizedBox(
          height: 40,
          child: AppNetworkImage(url: _url, fallback: Icon(Icons.layers)),
        ),
      )));

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      expect(image.memCacheWidth, isNotNull);
      expect(image.memCacheWidth, lessThanOrEqualTo(2048));
    });

    testWidgets('shows the fallback for an empty url', (tester) async {
      await tester.pumpWidget(_wrap(const AppNetworkImage(
        url: '',
        width: 40,
        height: 40,
        fallback: Icon(Icons.layers),
      )));

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('treats a whitespace-only url as empty', (tester) async {
      await tester.pumpWidget(_wrap(const AppNetworkImage(
        url: '  ',
        width: 40,
        height: 40,
        fallback: Icon(Icons.layers),
      )));

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });
  });
}
