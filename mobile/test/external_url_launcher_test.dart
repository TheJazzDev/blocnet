import 'package:blocnet/shared/utils/external_url_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preferredNativeAppUris builds X app URI for profile links', () {
    final uris = preferredNativeAppUris(Uri.parse('https://x.com/blocnet_app'));

    expect(
      uris.map((uri) => uri.toString()),
      contains('twitter://user?screen_name=blocnet_app'),
    );
  });

  test('launchExternalUrlWithAppFallback prefers app URI when available',
      () async {
    final launched = <String>[];

    final opened = await launchExternalUrlWithAppFallback(
      'https://x.com/blocnet_app',
      canLaunchUri: (uri) async => uri.scheme == 'twitter',
      launchExternalUri: (uri) async {
        launched.add(uri.toString());
        return true;
      },
    );

    expect(opened, isTrue);
    expect(launched, isNotEmpty);
    expect(launched.first, startsWith('twitter://'));
    expect(launched, isNot(contains('https://x.com/blocnet_app')));
  });

  test('launchExternalUrlWithAppFallback falls back to web URL when needed',
      () async {
    final launched = <String>[];

    final opened = await launchExternalUrlWithAppFallback(
      'https://x.com/blocnet_app',
      canLaunchUri: (_) async => false,
      launchExternalUri: (uri) async {
        launched.add(uri.toString());
        return uri.toString() == 'https://x.com/blocnet_app';
      },
    );

    expect(opened, isTrue);
    expect(launched.last, 'https://x.com/blocnet_app');
  });

  test('launchExternalUrlWithAppFallback returns false for invalid URL',
      () async {
    final opened = await launchExternalUrlWithAppFallback(
      '',
      canLaunchUri: (_) async => true,
      launchExternalUri: (_) async => true,
    );

    expect(opened, isFalse);
  });
}
