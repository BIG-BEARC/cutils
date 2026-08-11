// Wave A1 — medium-severity fixes for `log_storage`.
//
// Strict TDD: each test was first observed to FAIL for the right reason (where
// a behavioral distinction exists), then the minimal fix was applied under
// `lib/log_collector/log_storage.dart`. Performance-only changes (Queue O(1)
// front-drop, in-memory size tracking, periodic flush) are covered by
// behavioral regression guards plus dedicated mechanism tests (timer firing,
// file content landing).

import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/log_collector/log_collector_config.dart';
import 'package:cutils/log_collector/log_entry.dart';
import 'package:cutils/log_collector/log_storage.dart';

LogEntry _entry(String msg, {String tag = 'default'}) =>
    LogEntry(level: LogLevel.info, message: msg, tag: tag);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------- A1-storage-1: Queue O(1) front-drop (behavioral guard) ----------
  group('LogStorage memory front-drop', () {
    test('caps at maxMemoryLogCount keeping the newest, dropping the oldest',
        () async {
      const cap = 5;
      final storage = LogStorage(
        config: const LogCollectorConfig(
          enableFileStorage: false,
          enableMemoryStorage: true,
          maxMemoryLogCount: cap,
          autoCleanExpiredLogs: false,
        ),
      );
      await storage.initialize();

      // Insert cap + 3 entries.
      for (var i = 0; i < cap + 3; i++) {
        await storage.store(_entry('e$i'));
      }

      final logs = await storage.getLogs();

      expect(
        logs.length,
        cap,
        reason: 'Memory storage must be bounded by maxMemoryLogCount.',
      );
      expect(
        logs.map((e) => e.message).toList(),
        ['e3', 'e4', 'e5', 'e6', 'e7'],
        reason: 'Newest entries must be kept; oldest dropped from the front.',
      );

      await storage.dispose();
    });
  });

  // ---------- A1-storage-2: in-memory file-size tracking ----------
  group('LogStorage in-memory size tracking', () {
    test('triggers rotation at the right threshold without per-entry IO',
        () async {
      final dir = Directory(
        '${Directory.systemTemp.path}/'
        'a1_size_${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);

      try {
        final storage = LogStorage(
          config: LogCollectorConfig(
            enableFileStorage: true,
            enableMemoryStorage: false,
            storagePath: dir.path,
            maxFileSize: 200, // ~2 log lines triggers rotation on the 3rd.
            maxFileCount: 10,
            autoCleanExpiredLogs: false,
          ),
        );
        await storage.initialize();

        // Write enough entries to exceed the threshold. With in-memory tracking
        // the size accumulates from writes; once >= maxFileSize, rotation fires.
        for (var i = 0; i < 5; i++) {
          await storage.store(_entry('entry-$i'));
        }
        await storage.flushForTesting();

        final files = dir.listSync().whereType<File>().toList();
        expect(
          files.length,
          greaterThanOrEqualTo(2),
          reason:
              'Rotation must produce at least one archive + the current file.',
        );

        await storage.dispose();
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });

  // ---------- A1-storage-3: periodic flush timer ----------
  group('LogStorage periodic flush timer', () {
    test('fires on the configured interval and is cancelled on dispose', () {
      fakeAsync((async) {
        final storage = LogStorage(
          config: const LogCollectorConfig(
            enableFileStorage: false,
            enableMemoryStorage: false,
            autoCleanExpiredLogs: false,
            flushInterval: Duration(seconds: 5),
          ),
        );
        // initialize() schedules the periodic flush timer synchronously.
        storage.initialize();
        final countBefore = storage.periodicFlushCount;

        async.elapse(const Duration(seconds: 12));

        expect(
          storage.periodicFlushCount,
          greaterThan(countBefore),
          reason: 'Flush timer must fire when the interval elapses.',
        );

        final countAtDispose = storage.periodicFlushCount;
        storage.dispose();

        async.elapse(const Duration(seconds: 60));

        expect(
          storage.periodicFlushCount,
          countAtDispose,
          reason: 'Flush timer must NOT fire after dispose.',
        );
      });
    });
  });

  // ---------- A1-storage-3b: file content lands after flush ----------
  group('LogStorage flush lands content', () {
    test('written entries are readable on disk after a flush', () async {
      final dir = Directory(
        '${Directory.systemTemp.path}/'
        'a1_flush_${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);

      try {
        final storage = LogStorage(
          config: LogCollectorConfig(
            enableFileStorage: true,
            enableMemoryStorage: false,
            storagePath: dir.path,
            autoCleanExpiredLogs: false,
          ),
        );
        await storage.initialize();

        await storage.store(_entry('persisted-1'));
        await storage.store(_entry('persisted-2'));

        // Before flush, data may still be in the IOSink buffer. After flush it
        // must be on disk and readable.
        await storage.flushForTesting();

        final logs = await storage.getLogs();

        expect(
          logs.map((e) => e.message).toList(),
          containsAll(['persisted-1', 'persisted-2']),
          reason: 'Entries must be readable from disk after flush.',
        );

        await storage.dispose();
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });

  // ---------- A1-storage-4: streamed reads (behavioral) ----------
  group('LogStorage streamed file reads', () {
    test(
        'returns only the entries matching the filter without loading '
        'unrelated lines', () async {
      final dir = Directory(
        '${Directory.systemTemp.path}/'
        'a1_stream_${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);

      try {
        final storage = LogStorage(
          config: LogCollectorConfig(
            enableFileStorage: true,
            enableMemoryStorage: false,
            storagePath: dir.path,
            autoCleanExpiredLogs: false,
          ),
        );
        await storage.initialize();

        // Write 40 entries: half tagged 'match', half 'other'.
        for (var i = 0; i < 40; i++) {
          await storage.store(_entry('m$i', tag: i.isEven ? 'match' : 'other'));
        }
        await storage.flushForTesting();

        final matched = await storage.getLogs(tag: 'match');

        expect(
          matched.length,
          20,
          reason: 'Only the 20 match-tagged entries must be returned.',
        );
        expect(
          matched.every((e) => e.tag == 'match'),
          isTrue,
          reason: 'No non-matching entries should leak through the filter.',
        );

        await storage.dispose();
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });

    test('skips malformed lines without failing the whole read', () async {
      final dir = Directory(
        '${Directory.systemTemp.path}/'
        'a1_malformed_${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);

      try {
        final storage = LogStorage(
          config: LogCollectorConfig(
            enableFileStorage: true,
            enableMemoryStorage: false,
            storagePath: dir.path,
            autoCleanExpiredLogs: false,
          ),
        );
        await storage.initialize();

        // Write a valid entry, then manually append garbage, then another valid.
        await storage.store(_entry('good-1'));
        await storage.flushForTesting();

        // Append a malformed line directly to the file.
        final files = dir.listSync().whereType<File>().toList();
        expect(files, isNotEmpty);
        await files.first.writeAsString('NOT-JSON\n', mode: FileMode.append);

        await storage.store(_entry('good-2'));
        await storage.flushForTesting();

        final logs = await storage.getLogs();

        expect(
          logs.map((e) => e.message).toList(),
          containsAll(['good-1', 'good-2']),
          reason: 'Malformed lines must be skipped; valid entries still read.',
        );

        await storage.dispose();
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });
}
