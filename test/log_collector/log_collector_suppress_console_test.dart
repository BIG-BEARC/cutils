// Entry-level `suppressConsole` routing flag for `log_collector`.
//
// Strict TDD: this file was written against the agreed design first and
// observed to FAIL (missing `LogEntry.suppressConsole` / `LogOutput.isConsole`)
// before the minimal additive implementation landed under `lib/log_collector/`.
// Scope: suppressed entries still traverse the full collection pipeline
// (memory + file storage, getLogs/export) and only skip console-class outputs
// at the dispatch step in `LogCollector._processLogQueue`.

import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/log_collector/log_collector.dart';
import 'package:cutils/log_collector/log_collector_config.dart';
import 'package:cutils/log_collector/log_collector_helper.dart';
import 'package:cutils/log_collector/log_entry.dart';
import 'package:cutils/log_collector/log_output.dart';

/// A non-console [LogOutput] that records every entry it receives.
class _RecordingOutput extends LogOutput {
  final List<LogEntry> received = [];

  @override
  Future<void> output(LogEntry entry) async {
    received.add(entry);
  }
}

/// A console-class [LogOutput] stub: `isConsole == true` (the contract under
/// test) but records instead of printing, so tests stay noise-free.
class _ConsoleRecordingOutput extends LogOutput {
  final List<LogEntry> received = [];

  @override
  bool get isConsole => true;

  @override
  Future<void> output(LogEntry entry) async {
    received.add(entry);
  }
}

/// Pumps zero-delay macrotasks until [predicate] holds, so dispatch drains
/// deterministically without real wall-clock delays (same pattern as the
/// existing wave tests).
Future<void> _pumpUntil(bool Function() predicate) async {
  for (var i = 0; i < 200 && !predicate(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------- S1: LogEntry field and serialization ----------
  group('S1: LogEntry.suppressConsole field', () {
    test('defaults to false', () {
      final entry = LogEntry(level: LogLevel.info, message: 'm');
      expect(entry.suppressConsole, isFalse);
    });

    test('keeps the constructed value', () {
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'm',
        suppressConsole: true,
      );
      expect(entry.suppressConsole, isTrue);
    });

    test('does not leak into toJson', () {
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'm',
        suppressConsole: true,
      );
      expect(entry.toJson().containsKey('suppressConsole'), isFalse);
    });

    test('json round-trip resets the flag (routing is process-local)',
        () async {
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'm',
        suppressConsole: true,
      );
      final restored = LogEntry.fromJson(entry.toJson());
      expect(restored.suppressConsole, isFalse);
    });
  });

  // ---------- S2: collector dispatch ----------
  group('S2: LogCollector dispatch', () {
    setUp(() async => logCollector.dispose());
    tearDown(() async => logCollector.dispose());

    test('normal entry reaches console-like and regular outputs (regression)',
        () async {
      final console = _ConsoleRecordingOutput();
      final regular = _RecordingOutput();
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: true,
          autoCleanExpiredLogs: false,
        ),
        outputs: [console, regular],
      );

      await logCollector.collect(LogEntry(level: LogLevel.info, message: 'n'));
      await _pumpUntil(
        () => console.received.isNotEmpty && regular.received.isNotEmpty,
      );

      expect(console.received, hasLength(1));
      expect(regular.received, hasLength(1));
    });

    test('suppressed entry skips console output but still reaches storage',
        () async {
      final console = _ConsoleRecordingOutput();
      final regular = _RecordingOutput();
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: true,
          autoCleanExpiredLogs: false,
        ),
        outputs: [console, regular],
      );

      await logCollector.collect(
        LogEntry(level: LogLevel.info, message: 'q', suppressConsole: true),
      );
      // The regular output must still see the entry; wait for that signal
      // so the dispatch step has definitely run.
      await _pumpUntil(() => regular.received.isNotEmpty);

      expect(
        console.received,
        isEmpty,
        reason: 'Console-class outputs must not receive suppressed entries.',
      );
      expect(regular.received, hasLength(1));

      // Storage is unaffected: memory storage still holds the entry.
      final logs = await logCollector.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.single.message, 'q');
    });
  });

  // ---------- S3: BatchLogOutput forwarding ----------
  group('S3: BatchLogOutput isConsole forwarding', () {
    test('wrapping a console delegate reports isConsole true', () {
      final batch = BatchLogOutput(delegate: _ConsoleRecordingOutput());
      expect(batch.isConsole, isTrue);
    });

    test('nested batch(batch(console)) still reports isConsole true', () {
      final inner = BatchLogOutput(delegate: _ConsoleRecordingOutput());
      final outer = BatchLogOutput(delegate: inner);
      expect(outer.isConsole, isTrue);
    });

    test('suppressed entry is skipped by a batch wrapping a console delegate',
        () async {
      final console = _ConsoleRecordingOutput();
      final regular = _RecordingOutput();
      final batch = BatchLogOutput(delegate: console);
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
        ),
        outputs: [batch, regular],
      );

      await logCollector.collect(
        LogEntry(level: LogLevel.info, message: 'b', suppressConsole: true),
      );
      await logCollector.dispose(); // flushes the batch buffer

      expect(console.received, isEmpty);
      expect(regular.received, hasLength(1));
    });

    test('normal entry still flows through the batch to the console delegate',
        () async {
      final console = _ConsoleRecordingOutput();
      final batch = BatchLogOutput(delegate: console);
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
        ),
        outputs: [batch],
      );

      await logCollector.collect(LogEntry(level: LogLevel.info, message: 'f'));
      await logCollector.dispose(); // flushes the batch buffer

      expect(console.received, hasLength(1));
    });
  });

  // ---------- S4: dispose drain consistency ----------
  group('S4: dispose drain honors the flag', () {
    setUp(() async => logCollector.dispose());
    tearDown(() async => logCollector.dispose());

    test('entry collected right before dispose never reaches console output',
        () async {
      final console = _ConsoleRecordingOutput();
      final regular = _RecordingOutput();
      await logCollector.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
        ),
        outputs: [console, regular],
      );

      // Do not wait for the queue processor; dispose() drains the remainder
      // through the same _processLogQueue path and must apply the same rule.
      await logCollector.collect(
        LogEntry(level: LogLevel.info, message: 'd', suppressConsole: true),
      );
      await logCollector.dispose();

      expect(console.received, isEmpty);
      expect(regular.received, hasLength(1));
    });
  });

  // ---------- S5: helper pass-through ----------
  group('S5: LogCollectorHelper pass-through', () {
    setUp(() async => logCollector.dispose());
    tearDown(() async => logCollector.dispose());

    test('info() (delegating through log()) honors suppressConsole', () async {
      final console = _ConsoleRecordingOutput();
      final regular = _RecordingOutput();
      await LogCollectorHelper.instance.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
        ),
        outputs: [console, regular],
      );

      await LogCollectorHelper.info('h', suppressConsole: true);
      await _pumpUntil(() => regular.received.isNotEmpty);

      expect(console.received, isEmpty);
      expect(regular.received, hasLength(1));
    });

    test('error() (constructing directly) honors suppressConsole', () async {
      final console = _ConsoleRecordingOutput();
      final regular = _RecordingOutput();
      await LogCollectorHelper.instance.initialize(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: false,
          autoCleanExpiredLogs: false,
        ),
        outputs: [console, regular],
      );

      await LogCollectorHelper.error('e', suppressConsole: true);
      await _pumpUntil(() => regular.received.isNotEmpty);

      expect(console.received, isEmpty);
      expect(regular.received, hasLength(1));
    });
  });

  // ---------- S6: isConsole contract ----------
  group('S6: isConsole contract', () {
    test('ConsoleLogOutput reports isConsole true', () {
      expect(ConsoleLogOutput().isConsole, isTrue);
    });

    test('custom outputs default to isConsole false', () {
      expect(_RecordingOutput().isConsole, isFalse);
    });
  });
}
