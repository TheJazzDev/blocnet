import 'dart:async';

import 'package:blocnet/shared/application/feed/feed_sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trigger runs sync task at most once concurrently', () async {
    final controller = FeedSyncController(debugLabel: 'test');
    addTearDown(controller.dispose);

    final gate = Completer<void>();
    var runs = 0;

    Future<void> syncTask() async {
      runs += 1;
      await gate.future;
    }

    unawaited(controller.trigger(syncTask));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await controller.trigger(syncTask);
    expect(runs, 1);

    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 5));

    await controller.trigger(() async {
      runs += 1;
    });
    expect(runs, 2);
  });
}
