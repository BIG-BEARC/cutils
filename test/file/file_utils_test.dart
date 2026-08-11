import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:cutils/file/file_utils.dart'; // 替换为你的导入路径

/// Mock 平台 PathProvider
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fileUtils = FileUtils();
  final mockPlatform = MockPathProviderPlatform();

  // 设置平台
  PathProviderPlatform.instance = mockPlatform;

  final String tempPath = Directory.systemTemp.path;
  final Directory tempDir = Directory(tempPath)..createSync(recursive: true);

  setUpAll(() {
    registerFallbackValue(Directory(tempPath));
  });

  group('FileUtils basic operations', () {
    setUp(() {
      // Mock 各平台目录返回
      when(() => mockPlatform.getTemporaryPath())
          .thenAnswer((_) async => tempDir.path);
      when(() => mockPlatform.getApplicationDocumentsPath())
          .thenAnswer((_) async => tempDir.path);
      when(() => mockPlatform.getApplicationSupportPath())
          .thenAnswer((_) async => tempDir.path);
      when(() => mockPlatform.getExternalStoragePath())
          .thenAnswer((_) async => tempDir.path);
    });

    test('getPlatformPath returns a valid path', () async {
      final path = await fileUtils.getPlatformPath();
      expect(path, isNotNull);
      expect(Directory(path!).existsSync(), isTrue);
    });

    test('write and read string file', () async {
      const fileName = 'test_string.txt';
      const content = 'Hello, FileUtils!';
      final file = await fileUtils.writeString(
        str: content,
        fileName: fileName,
      );
      expect(file, isNotNull);
      final readContent = await fileUtils.readString(file!);
      expect(readContent, contains(content));
    });

    test('write and read json file', () async {
      final path = '${tempDir.path}/json_test.json';
      final jsonMap = {'platform': 'flutter', 'version': 3};
      await fileUtils.writeJsonCustomFile(jsonMap, path);
      final readStr = await fileUtils.readStringCustomFile(path);
      expect(readStr, contains('flutter'));
    });

    test('file to base64 and back', () async {
      final bytes = utf8.encode('base64 test');
      final originFile = File('${tempDir.path}/origin.txt')
        ..writeAsBytesSync(bytes);
      final base64 = await fileUtils.createBase64FromFile(originFile);
      final newFile = await fileUtils.createFileFromBase64(base64);
      expect(await newFile.exists(), isTrue);
      final newBytes = await newFile.readAsBytes();
      expect(newBytes, equals(bytes));
    });

    test('deleteFileData clears file content', () async {
      final filePath = '${tempDir.path}/delete_test.txt';
      final file = File(filePath)..writeAsStringSync('delete me');
      final result = await fileUtils.deleteFileData(filePath);
      expect(result, isTrue);
      expect(await file.exists(), isFalse);
    });

    test('clearFileData clears file content', () async {
      final filePath = '${tempDir.path}/clear_test.txt';
      final file = File(filePath)..writeAsStringSync('clear me');
      final result = await fileUtils.clearFileData(filePath);
      expect(result, isTrue);
      final content = await file.readAsString();
      expect(content, isEmpty);
    });

    test('getFileName parses filename from path', () {
      const filePath = '/user/logs/mylog_2025.txt';
      final name = fileUtils.getFileName(filePath);
      expect(name, 'mylog_2025');
    });
  });

  group('Wave A high-severity fixes', () {
    setUp(() {
      when(() => mockPlatform.getTemporaryPath())
          .thenAnswer((_) async => tempDir.path);
      when(() => mockPlatform.getApplicationDocumentsPath())
          .thenAnswer((_) async => tempDir.path);
      when(() => mockPlatform.getApplicationSupportPath())
          .thenAnswer((_) async => tempDir.path);
      when(() => mockPlatform.getExternalStoragePath())
          .thenAnswer((_) async => tempDir.path);
    });

    test('A1: readBySink returns file content instead of empty string',
        () async {
      const content = 'line one\nline two\nline three';
      final file = File('${tempDir.path}/a1_read_by_sink.txt')
        ..writeAsStringSync(content);
      final result = await fileUtils.readBySink(file, null);
      expect(result, isNot(equals('')));
      expect(result, equals('line oneline twoline three'));
    });

    test('A2: cleanExpiredLog deletes only files older than retention',
        () async {
      final logDir = Directory('${tempDir.path}/a2_clean_expired')
        ..createSync();
      final oldFile = File('${logDir.path}/old.log')..writeAsStringSync('old');
      oldFile.setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 3)));
      final currentFile = File('${logDir.path}/current.log')
        ..writeAsStringSync('current');

      // retentionTime is in milliseconds; 2 days.
      fileUtils.cleanExpiredLog(logDir.path, 2 * 24 * 60 * 60 * 1000);
      // cleanExpiredLog is `void ... async` (signature locked) and iterates
      // the directory via an `await for` stream, so its side effect is not
      // directly awaitable. Pump zero-delay macrotasks until oldFile is gone
      // — the bounded loop drains the event queue deterministically without
      // sleeping real time.
      for (var i = 0; i < 200 && oldFile.existsSync(); i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(oldFile.existsSync(), isFalse,
          reason: 'old file past retention should be deleted');
      expect(currentFile.existsSync(), isTrue,
          reason: 'current file within retention must remain');
    });

    test('A3: deleteFileData awaits the delete before returning', () async {
      // Deleting a nonexistent path rejects the underlying Future. With the
      // bug (delete not awaited) the error never reaches the catch, so the
      // function wrongly reports success. With the fix the await lets the
      // throw be caught and the function returns false.
      final missing =
          '${tempDir.path}/a3_definitely_missing_${DateTime.now().microsecondsSinceEpoch}.txt';
      final result = await fileUtils.deleteFileData(missing);
      expect(result, isFalse,
          reason: 'a failed delete must be observed, not silently dropped');
    });

    test('A3: zipFiles produces a decodable zip', () async {
      // Lay down a .log file that getFileList() will pick up.
      final logFile = File('${tempDir.path}/a3_zip.log')
        ..writeAsStringSync('log content for zip');
      final zip = await fileUtils.zipFiles('a3_logs');
      try {
        await logFile.delete();
      } catch (_) {}
      expect(zip, isNotNull);
      expect(zip!.existsSync(), isTrue);
      final bytes = await zip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.isNotEmpty, isTrue);
      try {
        await zip.delete();
      } catch (_) {}
    });

    test('A4: deleteLog honors the saveDays parameter', () async {
      final old1 = File('${tempDir.path}/a4_savelog_10.log')
        ..writeAsStringSync('five days old');
      final old2 = File('${tempDir.path}/a4_savelog_2.log')
        ..writeAsStringSync('five days old');
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      old1.setLastModifiedSync(fiveDaysAgo);
      old2.setLastModifiedSync(fiveDaysAgo);

      // deleteLog is `void ... async` (signature locked): it awaits a single
      // platform path lookup then runs the list/filter/delete synchronously.
      // We cannot await it directly, so we deterministically drain the event
      // queue with zero-delay macrotasks and observe the side effect.
      fileUtils.deleteLog(saveDays: 10);
      // saveDays=10 must keep the 5-day-old file; the deletion never happens,
      // so there is no condition to poll on — pump a bounded number of
      // turns to let the awaited path lookup resolve and the sync body run.
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(old1.existsSync(), isTrue,
          reason: '5-day-old file must remain when saveDays=10');

      fileUtils.deleteLog(saveDays: 2);
      // saveDays=2 must delete the 5-day-old file; poll until it is gone.
      for (var i = 0; i < 200 && old2.existsSync(); i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(old2.existsSync(), isFalse,
          reason: '5-day-old file must be deleted when saveDays=2');
    });

    test('A5: rejects path traversal in fileName and filePath', () async {
      // _getFile is private and all public callers wrap it in try/catch,
      // so the observable contract is "returns null" rather than "throws".
      final viaName = await fileUtils.getLocalDocumentFile(
          fileName: '../../a5_escape_name');
      expect(viaName, isNull,
          reason: 'fileName traversal must be rejected, not escape base dir');

      final viaPath = await fileUtils.getLocalDocumentFile(
          fileName: 'innocent.txt', filePath: '../../a5_escape_path');
      expect(viaPath, isNull,
          reason: 'filePath traversal must be rejected, not escape base dir');

      // Sanity: a normal relative name still resolves inside the base dir.
      final ok = await fileUtils.getLocalDocumentFile(fileName: 'a5_ok.txt');
      expect(ok, isNotNull);
      expect(ok!.path, contains(tempDir.path));
    });

    test('A6: createFileFromBase64 wraps invalid input in a typed exception',
        () async {
      await expectLater(
        fileUtils.createFileFromBase64('!!!notbase64!!!'),
        throwsA(isA<InvalidBase64Exception>()),
      );
    });
  });
}
