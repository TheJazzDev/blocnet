import 'package:blocnet/shared/application/realtime/realtime_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('scheduleDebounce only runs the latest task', () async {
    final coordinator = RealtimeCoordinator();
    addTearDown(coordinator.dispose);

    var runs = 0;
    coordinator.scheduleDebounce(
      'debounce-key',
      delay: const Duration(milliseconds: 20),
      task: () {
        runs += 1;
      },
    );
    coordinator.scheduleDebounce(
      'debounce-key',
      delay: const Duration(milliseconds: 20),
      task: () {
        runs += 1;
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(runs, 1);
  });

  test('handleStatusWithRecovery schedules one recovery task', () async {
    final coordinator = RealtimeCoordinator();
    addTearDown(coordinator.dispose);

    var subscribedRuns = 0;
    var recoveryRuns = 0;

    coordinator.handleStatusWithRecovery(
      key: 'channel-1',
      status: RealtimeSubscribeStatus.channelError,
      recoveryDelay: const Duration(milliseconds: 20),
      onSubscribed: () => subscribedRuns += 1,
      onRecover: () => recoveryRuns += 1,
    );
    coordinator.handleStatusWithRecovery(
      key: 'channel-1',
      status: RealtimeSubscribeStatus.timedOut,
      recoveryDelay: const Duration(milliseconds: 20),
      onSubscribed: () => subscribedRuns += 1,
      onRecover: () => recoveryRuns += 1,
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(subscribedRuns, 0);
    expect(recoveryRuns, 1);
  });

  test('handleStatusWithRecovery runs onSubscribed immediately', () {
    final coordinator = RealtimeCoordinator();
    addTearDown(coordinator.dispose);

    var subscribedRuns = 0;
    coordinator.handleStatusWithRecovery(
      key: 'channel-2',
      status: RealtimeSubscribeStatus.subscribed,
      recoveryDelay: const Duration(milliseconds: 20),
      onSubscribed: () => subscribedRuns += 1,
      onRecover: () {},
    );

    expect(subscribedRuns, 1);
  });
}
