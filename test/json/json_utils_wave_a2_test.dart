// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/json/json_utils.dart';

// 本测试文件会显式调用 deprecated 别名 printJson 以验证转发，文件级豁免。
// ignore_for_file: deprecated_member_use_from_same_package

/// Wave A2 — JsonUtils 中危修复测试。
///
/// 覆盖项：
/// - A2-4: `encodeObjectList([])` 返回 `"[]"`（不再返回 null）。
/// - A2-5: 大整数精度限制以 dartdoc 文档化；普通 int 仍可精确往返。
/// - A2-6: `printJson` → `logJson`（保留 deprecated 别名转发）。
void main() {
  group('A2-4 encodeObjectList empty list', () {
    test('empty list returns "[]" (not null)', () {
      final result = JsonUtils.encodeObjectList<Map<String, dynamic>>(
        <Map<String, dynamic>>[],
        (m) => m,
      );
      expect(result, equals('[]'));
    });

    test('non-empty list still encodes (regression)', () {
      final result = JsonUtils.encodeObjectList<Map<String, dynamic>>(
        <Map<String, dynamic>>[
          {'a': 1},
          {'b': 2},
        ],
        (m) => m,
      );
      expect(result, isNotNull);
      expect(result, contains('"a"'));
      expect(result, contains('"b"'));
    });

    test('null list still returns null (contract preserved)', () {
      final result = JsonUtils.encodeObjectList<Map<String, dynamic>>(
        null,
        (m) => m,
      );
      expect(result, isNull);
    });
  });

  group('A2-5 big-integer precision (documented limitation)', () {
    test('normal ints round-trip through encode/decode without loss', () {
      final encoded = json.encode({'id': 42});
      final decoded = json.decode(encoded) as Map<dynamic, dynamic>;
      expect(decoded, isA<Map<dynamic, dynamic>>());
      expect(decoded['id'], equals(42));
    });

    test('integer at the 2^53 boundary round-trips exactly', () {
      // 2^53 是 JavaScript 安全整数边界；该值及以下在 dart:convert 中精确无损。
      const boundary = 9007199254740992; // 2^53
      final encoded = JsonUtils.encodeObj({'id': boundary});
      final decoded = json.decode(encoded!);
      expect(decoded['id'], equals(boundary));
    });
  });

  // A2-6: printJson -> logJson (deprecated alias retained).
  group('A2-6 printJson -> logJson rename', () {
    /// PrettyPrinter (logger 包) 最终通过顶层 `print` 输出；在 zone 内拦截即可捕获。
    List<String> capturePrint(void Function() body) {
      final logged = <String>[];
      runZoned(
        () => body(),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logged.add(line),
        ),
      );
      return logged;
    }

    test('logJson pretty-encodes an object to logger output', () {
      final logged = capturePrint(() => JsonUtils.logJson({'x': 1, 'y': 'a'}));
      final joined = logged.join('\n');
      // PrettyPrinter 会加上时间戳/级别横幅，但 JSON 主体必然出现。
      expect(joined, contains('"x": 1'));
      expect(joined, contains('"y": "a"'));
    });

    test('logJson compact mode (prettyPrint=false) emits single-line JSON', () {
      final logged = capturePrint(
        () => JsonUtils.logJson({'x': 1}, prettyPrint: false),
      );
      expect(logged.join('\n'), contains('"x":1'));
    });

    test('deprecated printJson forwards to logJson (same JSON body)', () {
      // 同一输入，两个入口输出的 JSON 主体必须一致（时间戳横幅会不同，故只比较内容行）。
      bool isJsonBody(String l) =>
          l.contains('"') || l.contains('{') || l.contains('}');
      final outLog = capturePrint(() => JsonUtils.logJson({'x': 1, 'y': 'a'}))
          .where(isJsonBody)
          .join();
      final outPrint =
          capturePrint(() => JsonUtils.printJson({'x': 1, 'y': 'a'}))
              .where(isJsonBody)
              .join();
      expect(outPrint, equals(outLog));
    });
  });
}
