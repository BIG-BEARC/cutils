// Wave A1 — medium-severity fixes for `log_output`.
//
// Strict TDD: each test was first observed to FAIL for the right reason,
// then the minimal fix was applied under `lib/log_collector/log_output.dart`.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/log_collector/log_entry.dart';
import 'package:cutils/log_collector/log_output.dart';

/// A recording delegate: appends each received entry's message to [received]
/// and throws when an entry's message matches [throwOn].
class _RecordingOutput extends LogOutput {
  final List<String> received;
  final String? throwOn;

  _RecordingOutput(this.received, {this.throwOn});

  @override
  Future<void> output(LogEntry entry) async {
    if (throwOn != null && entry.message == throwOn) {
      throw StateError('boom on ${entry.message}');
    }
    received.add(entry.message);
  }
}

LogEntry _entry(String msg) => LogEntry(level: LogLevel.info, message: msg);

void main() {
  // ---------- A1-output-1: BatchLogOutput batch timer ----------
  group('BatchLogOutput periodic flush', () {
    test(
        'flushes buffered entries when batchInterval elapses without new '
        'entries', () {
      fakeAsync((async) {
        final received = <String>[];
        final batch = BatchLogOutput(
          delegate: _RecordingOutput(received),
          batchSize: 100,
          batchInterval: const Duration(seconds: 5),
        );

        // Buffer an entry without triggering flush (under batchSize, under
        // interval). With the bug, no Timer is armed and the entry waits
        // forever.
        batch.output(_entry('a'));
        expect(received, isEmpty, reason: 'Must not flush immediately.');

        // Advance PAST batchInterval WITHOUT feeding new entries.
        async.elapse(const Duration(seconds: 6));

        expect(
          received,
          ['a'],
          reason: 'A Timer(batchInterval) must flush buffered entries even '
              'when traffic stops.',
        );

        batch.dispose();
      });
    });
  });

  // ---------- A1-output-2: flush isolation ----------
  group('BatchLogOutput.flush isolation', () {
    test('a failing delegate.output does not drop remaining entries', () async {
      final received = <String>[];
      final batch = BatchLogOutput(
        delegate: _RecordingOutput(received, throwOn: 'bad'),
        batchSize: 100,
        batchInterval: const Duration(seconds: 5),
      );

      // Buffer three entries; none reach batchSize so no auto-flush.
      await batch.output(_entry('good1'));
      await batch.output(_entry('bad'));
      await batch.output(_entry('good2'));

      // Force a flush.
      await batch.flush();

      expect(
        received,
        containsAll(['good1', 'good2']),
        reason: 'Non-failing entries must still be output when the delegate '
            'throws on one entry.',
      );
      expect(
        received,
        isNot(contains('bad')),
        reason: 'The throwing entry must not be recorded.',
      );
    });
  });

  // ---------- A1-output-3: abstract / throwing stubs ----------
  group('FileLogOutput / NetworkLogOutput stubs', () {
    test('FileLogOutput constructor throws rather than silently no-op', () {
      expect(
        () => FileLogOutput(filePath: '/tmp/probe'),
        throwsA(isA<UnimplementedError>()),
        reason: 'Unimplemented stub must not be silently instantiable.',
      );
    });

    test('NetworkLogOutput constructor throws rather than silently no-op', () {
      expect(
        () => NetworkLogOutput(endpoint: 'http://example'),
        throwsA(isA<UnimplementedError>()),
        reason: 'Unimplemented stub must not be silently instantiable.',
      );
    });
  });

  // Guard against an unused-import lint since [debugPrint] is only referenced
  // transitively through the package under test in some analyzer configs.
  test('sanity: debugPrint is accessible', () {
    expect(debugPrint, isA<Function>());
  });
}
