import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `Image.network` has no disk cache and no decode sizing: every cold start
/// re-downloads the image, and a large upload is decoded at full resolution on
/// the UI isolate. `cached_network_image` is already a dependency, so there is
/// no reason for a remote image in this app to go through the raw widget.
///
/// This guards every call site at once, including ones added later.
void main() {
  test('no widget loads a remote image with an uncached Image.network', () {
    final offenders = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].trim();
        // Skip comments, so prose explaining the rule is not an offender.
        if (code.startsWith('//') || code.startsWith('*')) continue;
        if (code.contains('Image.network')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use CachedNetworkImage with memCacheWidth/memCacheHeight '
          'instead of Image.network at:\n${offenders.join('\n')}',
    );
  });
}
