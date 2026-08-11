// Wave B — medium-severity fixes for `ext/int_ext.dart` (B6).
//
// B6a: `percentFormat` dartdoc example referenced `0.25` which cannot
//      be a receiver of an `int?` extension. The example is corrected to
//      an int (behavior unchanged — still `this * 100`). An overflow
//      caveat is added to the dartdoc.
// B6b: `currencyFormatWithSymbol` inserted a space between the symbol
//      and the number (`"¥ 150.00"`). Removed per Chinese convention
//      (`"¥150.00"`).

import 'package:cutils/ext/int_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B6a percentFormat (int semantics)', () {
    test('multiplies the int by 100', () {
      // Pins the *100 semantics so the dartdoc example stays honest.
      expect(1.percentFormat, '100%');
      expect(2.percentFormat, '200%');
      expect(25.percentFormat, '2500%');
    });

    test('null int falls back to 0%', () {
      int? nil;
      expect(nil.percentFormat, '0%');
    });

    test('zero is 0%', () {
      expect(0.percentFormat, '0%');
    });
  });

  group('B6b currencyFormatWithSymbol — no space after symbol', () {
    test('default (two decimals) has no space after ¥', () {
      expect(15000.currencyFormatWithSymbol('¥'), '¥150.00');
    });

    test('autoMoneyUnit whole-yuan has no space after symbol', () {
      expect(
        15000.currencyFormatWithSymbol('¥', autoMoneyUnit: true),
        '¥150',
      );
    });

    test('full-width ￥ also has no space', () {
      expect(12345.currencyFormatWithSymbol('￥'), '￥123.45');
    });

    test('null falls back to symbol + 0.00 with no space', () {
      int? nil;
      expect(nil.currencyFormatWithSymbol('¥'), '¥0.00');
    });

    test('fractional autoMoneyUnit keeps its digits with no space', () {
      // 12358 / 100 = 123.58 → not whole → keeps 2 decimals.
      expect(
        12358.currencyFormatWithSymbol('\$', autoMoneyUnit: true),
        '\$123.58',
      );
    });
  });
}
