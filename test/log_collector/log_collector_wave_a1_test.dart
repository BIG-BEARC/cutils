// Wave A1 — medium-severity fixes for `log_collector`.
//
// Strict TDD: each test was first observed to FAIL for the right reason,
// then the minimal fix was applied under `lib/log_collector/log_collector.dart`.
// Only additive @visibleForTesting seams were introduced (no signature changes).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/log_collector/log_collector.dart';
import 'package:cutils/log_collector/log_collector_config.dart';
import 'package:cutils/log_collector/log_entry.dart';
import 'package:cutils/log_collector/log_interceptor.dart';
import 'package:cutils/log_collector/log_output.dart';
import 'package:cutils/log_collector/log_storage.dart';

/// Output that counts [output] calls.
class _CountingOutput extends LogOutput {
  int outputCalls = 0;

  @override
  Future<void> output(LogEntry entry) async {
    outputCalls++;
  }
}

/// Output that mutates the collector's output list during iteration by
/// removing itself, triggering ConcurrentModificationError without a snapshot.
class _SelfRemovingOutput extends LogOutput {
  int calls = 0;
  @override
  Future<void> output(LogEntry entry) async {
    calls++;
    logCollector.removeOutput(this);
  }
}

/// A [LogStorage] whose [store] throws on the first call then succeeds.
/// Inherits no file I/O because we override [store] entirely.
class _ThrowOnceStorage extends LogStorage {
  int storeCalls = 0;
  _ThrowOnceStorage({required super.config});

  @override
  Future<void> store(LogEntry entry) async {
    storeCalls++;
    if (storeCalls == 1) {
      throw StateError('storage boom');
    }
    // Subsequent calls: no-op (skip super to avoid file I/O).
  }
}

/// An interceptor whose [onStart] completes asynchronously and sets a flag.
class _AsyncStartInterceptor extends LogInterceptor {
  bool startedFlag = false;
  @override
  Future<void> onStart() async {
    await Future<void>.delayed(Duration.zero);
    startedFlag = true;
  }

  @override
  Future<void> onStop() async {}
}

const _noIoConfig = LogCollectorConfig(
  enableFileStorage: false,
  enableMemoryStorage: false,
  autoCleanExpiredLogs: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => logCollector.dispose());
  tearDown(() async => logCollector.dispose());

  // ---------- A1-collector-1: store try/catch ----------
  group('LogCollector store error isolation', () {
    test(
        'a throwing storage.store does not stall the queue — subsequent '
        'entries still drain and output', () async {
      await logCollector.initialize(config: _noIoConfig);

      // Inject a storage that throws once then succeeds.
      final throwingStorage = _ThrowOnceStorage(config: _noIoConfig);
      logCollector.storageForTesting = throwingStorage;

      final counter = _CountingOutput();
      logCollector.addOutput(counter);

      // Pump 3 entries synchronously. The storage throws on the first.
      // Without the try/catch, the while-loop aborts and entries 2-3 never
      // reach the output (they stay queued).
      for (var i = 0; i < 3; i++) {
        unawaited(
          logCollector.collect(
            LogEntry(level: LogLevel.info, message: 'e$i'),
          ),
        );
      }

      // Drain deterministically.
      for (var i = 0; i < 300 && counter.outputCalls < 3; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        counter.outputCalls,
        3,
        reason: 'All 3 entries must be forwarded to the output even when '
            'storage.store throws on the first.',
      );
      expect(
        throwingStorage.storeCalls,
        3,
        reason: 'All 3 store calls must be attempted (loop must not abort).',
      );
    });
  });

  // ---------- A1-collector-2: snapshot iteration of _outputs ----------
  group('LogCollector output iteration safety', () {
    test('an output that mutates _outputs mid-iteration does not throw CME',
        () async {
      await logCollector.initialize(config: _noIoConfig);

      final selfRemoving = _SelfRemovingOutput();
      logCollector.addOutput(selfRemoving);

      // If _outputs is iterated directly (not snapshotted), the
      // removeOutput() call inside output() triggers a
      // ConcurrentModificationError on the next moveNext().
      await logCollector.collect(
        LogEntry(level: LogLevel.info, message: 'x'),
      );
      for (var i = 0; i < 100 && selfRemoving.calls < 1; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        selfRemoving.calls,
        1,
        reason: 'The self-removing output must have been invoked exactly once '
            'without a ConcurrentModificationError.',
      );
    });
  });

  // ---------- A1-collector-3: await interceptor.start ----------
  group('LogCollector.initialize awaits interceptor.start', () {
    test(
        'an interceptor whose start sets a flag asynchronously is complete '
        'before initialize returns', () async {
      final interceptor = _AsyncStartInterceptor();

      await logCollector.initialize(
        config: _noIoConfig,
        interceptors: [interceptor],
      );

      expect(
        interceptor.startedFlag,
        isTrue,
        reason: 'interceptor.start must be awaited so its async work '
            'completes before initialize returns.',
      );
    });
  });
}
