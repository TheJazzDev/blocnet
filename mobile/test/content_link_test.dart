import 'package:blocnet/services/core/content_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentLink.parse', () {
    test('reads the paths the app shares', () {
      expect(
        ContentLink.parse('/updates/u1'),
        const ContentLink(ContentLinkKind.update, 'u1'),
      );
      expect(
        ContentLink.parse('/projects/p1'),
        const ContentLink(ContentLinkKind.gem, 'p1'),
      );
      expect(
        ContentLink.parse('/community/c1'),
        const ContentLink(ContentLinkKind.communityPost, 'c1'),
      );
    });

    test('reads the notification forms too', () {
      expect(
        ContentLink.parse('/community/posts/c2'),
        const ContentLink(ContentLinkKind.communityPost, 'c2'),
      );
      expect(
        ContentLink.parse('/gems/p2'),
        const ContentLink(ContentLinkKind.gem, 'p2'),
      );
    });

    test('ignores lists and gem sub-tabs', () {
      expect(ContentLink.parse('/updates'), isNull);
      expect(ContentLink.parse('/projects/'), isNull);
      expect(ContentLink.parse('/gems/board'), isNull);
      expect(ContentLink.parse('/gems/hunters'), isNull);
      expect(ContentLink.parse('/community/posts'), isNull);
      expect(ContentLink.parse('/wallet'), isNull);
    });
  });
}
