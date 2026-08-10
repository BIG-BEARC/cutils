// Wave A1 — medium-severity fix for `event_bus`.
//
// Strict TDD: the test was first observed to FAIL for the right reason
// (listener still received events after dispose), then the minimal fix was
// applied under `lib/event/event_bus_util.dart` to turn it green.

import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/event/event_bus_util.dart';

class _TestEvent extends Event {
  final int value;
  _TestEvent(this.value);
}

/// Helper: pump the microtask queue until [condition] is true or we exhaust a
/// bounded retry count — deterministic, no real wall-clock delay.
Future<void> _pumpUntil(bool Function() condition,
    {int maxRounds = 200}) async {
  for (var i = 0; i < maxRounds && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // The singleton is disposed in these tests; subsequent tests in this file
  // re-create via the factory which returns the same (disposed) instance —
  // dispose() below recreates the internal controller so reuse works.
  group('EventBusUtil.dispose', () {
    test(
        'cancel all subscriptions and close the stream so disposed listeners '
        'receive nothing further', () async {
      final bus = EventBusUtil();
      var received = 0;

      bus.listen<_TestEvent>((e) => received++);

      bus.fire(_TestEvent(1));
      await _pumpUntil(() => received >= 1);
      expect(received, 1,
          reason: 'Listener should receive the pre-dispose event.');

      await bus.dispose();

      // After dispose the controller is closed; fire is a no-op.
      bus.fire(_TestEvent(2));
      await _pumpUntil(() => received >= 2, maxRounds: 50);
      expect(
        received,
        1,
        reason: 'Disposed listener must NOT receive events after dispose().',
      );
    });
  });
}
