import 'dart:convert';
import 'dart:io';

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
}
