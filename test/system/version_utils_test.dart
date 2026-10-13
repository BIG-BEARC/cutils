// VersionUtils — absorbed (rewritten, tightened error semantics) from
// saas_pos_smart_edition `lib/core/utils/version_compare_util.dart`.
//
// Strict TDD: written first; expected to fail with compile errors before
// `lib/system/version_utils.dart` exists. Deviations from the source on
// purpose:
// - generic three-state `compare` core instead of a single boolean question;
// - empty input throws [ArgumentError] (source silently returned `false`);
// - non-numeric segments are treated as whole-zero `0`, documented.

import 'package:cutils/cutils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V1 compare 基础三态', () {
    test('相等返回 0', () {
      expect(VersionUtils.compare('1.0.0', '1.0.0'), 0);
    });

    test('a 大返回 1', () {
      expect(VersionUtils.compare('1.2.0', '1.1.9'), 1);
    });

    test('a 小返回 -1', () {
      expect(VersionUtils.compare('1.1.9', '1.2.0'), -1);
    });

    test('按数值比较而非字典序（1.10.0 > 1.9.0）', () {
      expect(VersionUtils.compare('1.10.0', '1.9.0'), 1);
    });
  });

  group('V2 v/V 前缀与空白', () {
    test('v 前缀剥离', () {
      expect(VersionUtils.compare('v1.2.0', '1.2.0'), 0);
    });

    test('V 大写前缀剥离', () {
      expect(VersionUtils.compare('V2.0.0', '1.9.9'), 1);
    });

    test('两端空白 trim', () {
      expect(VersionUtils.compare(' 1.2.0 ', '1.2.0'), 0);
    });
  });

  group('V3 段数不等时的长度差兜底', () {
    test('缺段视为更小（1.0 < 1.0.1）', () {
      expect(VersionUtils.compare('1.0', '1.0.1'), -1);
      expect(VersionUtils.compare('1.0.1', '1.0'), 1);
    });

    test('段数不同但前段全等且等长值（1.0 == 1）', () {
      expect(VersionUtils.compare('1.0', '1'), 0);
    });
  });

  group('V4 非数字段视为 0（不解析预发布标签）', () {
    test('非数字段当 0 参与比较', () {
      expect(VersionUtils.compare('1.a.0', '1.0.0'), 0);
      expect(VersionUtils.compare('1.0.1', '1.0.beta'), 1);
    });

    test('预发布后缀不解析（1.0.0-beta 与 1.0.0 视为相等）', () {
      expect(VersionUtils.compare('1.0.0-beta', '1.0.0'), 0);
    });

    test('带符号段视为 0（严格纯数字段解析，不按值参与）', () {
      expect(VersionUtils.compare('1.-1.0', '1.0.0'), 0);
      expect(VersionUtils.compare('1.+1.0', '1.0.0'), 0);
    });

    test('纯数字段溢出 int 范围视为 0', () {
      // 20 个 9 超出 int64：tryParse 失败按 0 参与，'1.0' < '1.1'
      expect(VersionUtils.compare('1.99999999999999999999', '1.1'), -1);
    });
  });

  group('V5 空输入抛 ArgumentError（不静默）', () {
    test('a 为空抛错', () {
      expect(() => VersionUtils.compare('', '1.0.0'), throwsArgumentError);
    });

    test('b 为空抛错', () {
      expect(() => VersionUtils.compare('1.0.0', '  '), throwsArgumentError);
    });

    test('单字符 v/V 剥前缀后为空，抛 ArgumentError（不再绕过空判）', () {
      expect(() => VersionUtils.compare('v', '0'), throwsArgumentError);
      expect(() => VersionUtils.compare('V', '0'), throwsArgumentError);
    });
  });

  group('V6 isNewer 便捷', () {
    test('服务端更新返回 true', () {
      expect(
        VersionUtils.isNewer(serverVersion: '1.1.0', clientVersion: '1.0.9'),
        isTrue,
      );
    });

    test('相等与更旧返回 false', () {
      expect(
        VersionUtils.isNewer(serverVersion: '1.0.0', clientVersion: '1.0.0'),
        isFalse,
      );
      expect(
        VersionUtils.isNewer(serverVersion: '1.0.9', clientVersion: '1.1.0'),
        isFalse,
      );
    });

    test('v 前缀混用', () {
      expect(
        VersionUtils.isNewer(serverVersion: 'v1.1.0', clientVersion: '1.0.9'),
        isTrue,
      );
    });
  });
}
