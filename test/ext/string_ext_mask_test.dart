// 脱敏扩展 — absorbed (as capability, rewritten) from
// saas_pos_smart_edition `lib/shared/extensions/string_extensions.dart`.
//
// Strict TDD: written first. Semantic decisions frozen per plan review:
// - fixed star counts per tier (4/3/2 stars), matching the source;
// - dial-code prefix rejoined as `'<prefix> <masked>'` (space separated);
// - masking rebuilds from digits only (non-digit separators are dropped);
// - negative head/tail throws ArgumentError (not-silent baseline).

import 'package:cutils/ext/string_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M1 maskMobile 分级脱敏（原地升级：非 11 位不再原样返回）', () {
    test('11 位手机号（与既有行为一致）', () {
      expect('13812345678'.maskMobile, '138****5678');
    });

    test('10 位（≥10 档：前3后4，固定 4 星）', () {
      expect('5551234567'.maskMobile, '555****4567');
    });

    test('7 位（7-9 档：前2后2，固定 3 星）', () {
      expect('1234567'.maskMobile, '12***67');
    });

    test('4 位（4-6 档：前1后1，固定 2 星）', () {
      expect('1234'.maskMobile, '1**4');
    });

    test('不足 4 位不脱敏（显式决策：原样返回，含带国家码前缀短号）', () {
      expect('123'.maskMobile, '123');
      expect('1'.maskMobile, '1');
      expect('+1 23'.maskMobile, '+1 23');
      expect('+8612'.maskMobile, '+8612');
    });

    test('空串返回空串', () {
      expect(''.maskMobile, '');
    });

    test('国家码前缀保留并以空格拼回（启发式：带空格形态可正确切分）', () {
      expect('+86 13812345678'.maskMobile, '+86 138****5678');
      expect('+1 555 123 4567'.maskMobile, '+1 555****4567');
    });

    test('仅按数字位定级（非数字分隔符剔除，输出由数字重建）', () {
      expect('138-1234-5678'.maskMobile, '138****5678');
    });

    test('无数字内容原样返回', () {
      expect('abc'.maskMobile, 'abc');
      expect('+abc'.maskMobile, '+abc');
    });
  });

  group('M2 maskMobileOr（可空安全）', () {
    test('null 返回 fallback', () {
      expect(null.maskMobileOr(), '');
      expect(null.maskMobileOr(fallback: '--'), '--');
    });

    test('空串返回 fallback', () {
      expect(''.maskMobileOr(fallback: '--'), '--');
    });

    test('正常脱敏', () {
      expect('13812345678'.maskMobileOr(fallback: '--'), '138****5678');
    });
  });

  group('M3 maskMiddle（保留头尾通用脱敏）', () {
    test('默认 4 星占位', () {
      expect('张三丰'.maskMiddle(head: 1, tail: 1), '张****丰');
    });

    test('自定义占位符', () {
      expect(
          'ABCDEFGH'.maskMiddle(head: 2, tail: 2, placeholder: '##'), 'AB##GH');
    });

    test('头尾均 0 即全脱敏', () {
      expect('SECRET'.maskMiddle(), '****');
    });

    test('等价手机号场景：前 3 后 4', () {
      expect('13812345678'.maskMiddle(head: 3, tail: 4), '138****5678');
    });

    test('长度不足头尾之和时原样返回（不脱敏短串）', () {
      expect('abc'.maskMiddle(head: 2, tail: 2), 'abc');
    });

    test('负 head/tail 抛 ArgumentError（不静默基线）', () {
      expect(() => 'abc'.maskMiddle(head: -1, tail: 1), throwsArgumentError);
      expect(() => 'abc'.maskMiddle(head: 1, tail: -1), throwsArgumentError);
    });
  });

  group('M4 maskMiddleOr（可空安全，fallback 可选默认空串）', () {
    test('null 返回 fallback', () {
      expect(null.maskMiddleOr(fallback: '--', head: 1, tail: 1), '--');
      expect(null.maskMiddleOr(), '');
    });

    test('空串返回 fallback', () {
      expect(''.maskMiddleOr(fallback: '--', head: 1, tail: 1), '--');
    });

    test('正常脱敏', () {
      expect('ID-12345678'.maskMiddleOr(fallback: '--', head: 3, tail: 4),
          'ID-****5678');
    });
  });
}
