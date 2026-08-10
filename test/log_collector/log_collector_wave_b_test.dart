// Wave B — high-severity bug fixes for `log_collector`.
//
// Strict TDD: each group was first observed to FAIL for the right reason,
// then the minimal fix was applied under `lib/log_collector/` to turn it
// green. No public signatures were changed; only additive fields/getters
// were introduced (LogCollectorConfig.maxQueueSize, LogCollector.pendingLogCount).

import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/log_collector/log_collector.dart';
import 'package:cutils/log_collector/log_collector_config.dart';
import 'package:cutils/log_collector/log_entry.dart';
import 'package:cutils/log_collector/log_interceptor.dart';
import 'package:cutils/log_collector/log_output.dart';
import 'package:cutils/log_collector/log_storage.dart';

/// A [LogOutput] that counts calls, optionally delays, and records whether
/// [dispose] was invoked.
class _CountingOutput extends LogOutput {
  int outputCalls = 0;
  final Duration delay;
  bool disposeWasCalled = false;

  _CountingOutput({this.delay = Duration.zero});

  @override
  Future<void> output(LogEntry entry) async {
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    outputCalls++;
  }

  @override
  Future<void> dispose() async {
    disposeWasCalled = true;
  }
}

/// A [LogStorage] subclass that counts cleanup invocations without touching
/// the filesystem, so it can be driven inside [fakeAsync].
class _SpyStorage extends LogStorage {
  int cleanupCalls = 0;

  _SpyStorage({required super.config});

  @override
  Future<void> cleanupExpiredLogs() async {
    cleanupCalls++;
    // Intentionally skip super to keep the test free of filesystem I/O.
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------- B1: ExceptionInterceptor recursion ----------
  group('B1: ExceptionInterceptor.onError recursion', () {
    test('invokes the previous handler exactly once without recursing',
        () async {
      final void Function(FlutterErrorDetails)? original = FlutterError.onError;
      int prevCalls = 0;
      FlutterError.onError = (FlutterErrorDetails details) {
        prevCalls++;
      };

      try {
        final interceptor = ExceptionInterceptor();
        await interceptor.start(logCollector);

        final details = FlutterErrorDetails(
          exception: Exception('boom'),
          stack: StackTrace.current,
        );

        // Buggy code calls FlutterError.presentError(details), which reroutes
        // back through FlutterError.onError -> infinite recursion ->
        // StackOverflowError. Fixed code calls the captured previous handler
        // directly.
        FlutterError.onError!.call(details);

        expect(
          prevCalls,
          1,
          reason:
              'Previous onError must be invoked exactly once, not recursed.',
        );

        await interceptor.stop();
      } finally {
        FlutterError.onError = original;
      }
    });
  });

  // ---------- B2: _rotateLogFile no-op ----------
  group('B2: LogStorage rotation', () {
    test('renames the old file and points to a new file', () async {
      final dir = Directory(
        '${Directory.systemTemp.path}/'
        'b2_rotate_${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);

      try {
        final storage = LogStorage(
          config: LogCollectorConfig(
            enableFileStorage: true,
            enableMemoryStorage: false,
            storagePath: dir.path,
            maxFileSize: 1, // 1 byte -> any write triggers rotation next call.
            maxFileCount: 10,
            autoCleanExpiredLogs: false,
          ),
        );
        await storage.initialize();

        // First store creates the file on disk and writes > 1 byte.
        await storage.store(LogEntry(level: LogLevel.info, message: 'first'));
        // Second store sees the oversized file and must rotate.
        await storage.store(LogEntry(level: LogLevel.info, message: 'second'));

        final files = dir.listSync().whereType<File>().toList();
        expect(
          files.length,
          greaterThanOrEqualTo(2),
          reason: 'Rotation must produce a renamed archive plus a new file.',
        );

        final hasArchive = files.any((f) {
          final name = f.uri.pathSegments.last;
          // Archive: log_YYYY-MM-DD_HHMMSS.json
          return RegExp(r'^log_\d{4}-\d{2}-\d{2}_\d{6}\.json$').hasMatch(name);
        });
        expect(
          hasArchive,
          isTrue,
          reason: 'Archived file must exist with a distinct timestamp suffix.',
        );

        await storage.dispose();
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });

  // ---------- B3: Timer.periodic leak ----------
  group('B3: _scheduleCleanup timer cancellation', () {
    test('cleanup does not fire after dispose', () {
      fakeAsync((async) {
        final storage = _SpyStorage(
          config: const LogCollectorConfig(
            enableFileStorage: false,
            enableMemoryStorage: false,
            autoCleanExpiredLogs: true,
          ),
        );
        // initialize() schedules the periodic cleanup timer synchronously.
        storage.initialize();
        // dispose() must cancel the timer so it can never fire again.
        storage.dispose();

        // Advance well past the daily interval.
        async.elapse(const Duration(days: 2));

        expect(
          storage.cleanupCalls,
          0,
          reason: 'Cleanup timer must not fire after dispose.',
        );
      });
    });
  });

  // ---------- B4: dispose propagates to outputs ----------
  group('B4: LogCollector.dispose disposes outputs', () {
    setUp(() async => logCollector.dispose());
    tearDown(() async => logCollector.dispose());

    test('calls dispose on each registered output', () async {
      final fake = _CountingOutput();
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
        ),
        outputs: [fake],
      );
      await logCollector.dispose();

      expect(
        fake.disposeWasCalled,
        isTrue,
        reason:
            'dispose() must propagate to each output (e.g. BatchLogOutput.flush).',
      );
    });
  });

  // ---------- B5: _logQueue cap ----------
  group('B5: LogCollector queue cap', () {
    setUp(() async => logCollector.dispose());
    tearDown(() async => logCollector.dispose());

    test('does not let the in-flight queue exceed maxQueueSize', () async {
      const cap = 5;
      final slow = _CountingOutput(delay: const Duration(milliseconds: 5));
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
          maxQueueSize: cap,
        ),
        outputs: [slow],
      );

      // Pump many more than the cap synchronously. The slow output holds the
      // processor, so without the cap the queue would grow to ~pumpCount.
      for (var i = 0; i < 50; i++) {
        unawaited(
          logCollector.collect(
            LogEntry(level: LogLevel.info, message: 'e$i'),
          ),
        );
      }

      expect(
        logCollector.pendingLogCount,
        lessThanOrEqualTo(cap),
        reason: 'Queue must be bounded by maxQueueSize.',
      );
    });
  });

  // ---------- B6: initialize double-init race ----------
  group('B6: LogCollector.initialize race', () {
    setUp(() async => logCollector.dispose());
    tearDown(() async => logCollector.dispose());

    test('concurrent initialize calls do not double-register outputs',
        () async {
      final counter = _CountingOutput();
      const config = LogCollectorConfig(
        enableFileStorage: false,
        enableMemoryStorage: false,
        autoCleanExpiredLogs: false,
      );

      // Fire both inits without awaiting the first; with the bug, both pass
      // `_isInitialized == false` during their awaits and outputs get added
      // twice.
      await Future.wait<void>([
        logCollector.initialize(config: config, outputs: [counter]),
        logCollector.initialize(config: config, outputs: [counter]),
      ]);

      // Give the queue processor a chance to drain the single entry.
      unawaited(
        logCollector.collect(
          LogEntry(level: LogLevel.info, message: 'x'),
        ),
      );
      // Pump the event loop so the queued entry is processed.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        counter.outputCalls,
        1,
        reason: 'Double-init must not duplicate registered outputs.',
      );
    });
  });

  // ---------- B7: ConsoleLogOutput uses print ----------
  group('B7: ConsoleLogOutput does not use print', () {
    test('routes through a non-print sink (debugPrint / developer.log)',
        () async {
      final output = ConsoleLogOutput();
      final entry = LogEntry(level: LogLevel.info, message: 'hello');

      // Fork a zone that fails if print is invoked at all.
      await runZoned<Future<void>>(
        () => output.output(entry),
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            throw StateError(
              'ConsoleLogOutput must not call print; got: $line',
            );
          },
        ),
      );
    });
  });
}
