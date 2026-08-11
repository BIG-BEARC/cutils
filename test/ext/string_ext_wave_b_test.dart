// Wave B — medium-severity fixes for `ext/string_ext.dart` (B4, B5).
//
// B4: `formatMoney` did `(money / 100).toString()`, emitting scientific
// notation for very large values and corrupting the last digit near the
// 2^53 boundary via FP division. Fixed by formatting from a [Decimal].
// Note: whole-number results now render without a trailing `.0` (e.g.
// `"100".formatMoney` → `"1"` instead of `"1.0"`) because Decimal does
// not synthesize a fractional part that is not there. This is a minor
// output-format change; non-whole results are byte-identical.
//
// B5: documents that `moneyFormatWithUnit` expects a *fen* (分) string.

import 'package:cutils/ext/string_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B4 formatMoney FP / scientific notation', () {
    test('9007199254740993 fen (2^53+1) preserves exact value', () {
      // Correct: 9007199254740993 / 100 = 90071992547409.93.
      // The old `(money/100).toString()` double path produced "...09.92".
      expect('9007199254740993'.formatMoney, '90071992547409.93');
    });

    test('very large fen value does not emit scientific notation', () {
      // 1e23 fen → 1e21 yuan. The double path could not represent 1e23
      // exactly; the Decimal path yields the exact, non-scientific form.
      final result = '100000000000000000000000'.formatMoney;
      expect(result, '1000000000000000000000');
      expect(result.contains('e'), isFalse);
    });

    test('non-whole values unchanged (regression)', () {
      expect('12345'.formatMoney, '123.45');
      expect('123'.formatMoney, '1.23');
      expect('5'.formatMoney, '0.05');
    });

    test('null / empty / non-numeric still return "--"', () {
      expect(null.formatMoney, '--');
      expect(''.formatMoney, '--');
      expect('abc'.formatMoney, '--');
    });
  });

  group('B5 moneyFormatWithUnit (fen input)', () {
    test('below the 万 threshold divides fen by 100', () {
      // 123456 fen = 1234.56 yuan.
      expect('123456'.moneyFormatWithUnit(false), '1234.56');
    });

    test('autoMoneyUnit collapses >= 10000 yuan (1000000 fen) to 万', () {
      // 1000000 fen = 10000 yuan = 1.00万.
      expect('1000000'.moneyFormatWithUnit(true), '1.00万');
      // 12345678 fen ≈ 12.35万 yuan.
      expect('12345678'.moneyFormatWithUnit(true), '12.35万');
    });

    test('autoMoneyUnit=false never collapses', () {
      expect('1000000'.moneyFormatWithUnit(false), '10000.00');
    });

    test('null/empty returns "0.00"', () {
      expect(null.moneyFormatWithUnit(false), '0.00');
      expect(''.moneyFormatWithUnit(false), '0.00');
    });
  });
}
