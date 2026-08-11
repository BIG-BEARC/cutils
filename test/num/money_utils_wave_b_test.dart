// Wave B — medium-severity fixes for `num/money_utils.dart` (B2, B3).
//
// B2: `changeF2Y` formatted via Decimal→double→toStringAsFixed, so a fen
// amount at the 2^53 boundary lost integer precision before formatting
// (double round-trip). Fixed by formatting directly from Decimal.
//
// B3: `withUnit` had a `default:` arm that defeated enum exhaustiveness;
// rewritten as an exhaustive switch expression. Existing unit behavior is
// preserved.

import 'package:cutils/num/money_utils.dart';
import 'package:cutils/num/money_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B2 changeF2Y large fen precision', () {
    // 2^53 + 1 cannot be represented as a double; the double round-trip
    // (Decimal -> double -> toStringAsFixed) corrupts the last digit.
    test('9007199254740993 fen (2^53+1) preserves exact value', () {
      // Correct: 9007199254740993 / 100 = 90071992547409.93 exactly.
      // The old double round-trip produced "...09.92" (off by one).
      expect(
        MoneyUtils.changeF2Y(9007199254740993),
        '90071992547409.93',
      );
    });

    test('NORMAL format retains exact value for huge whole-yuan amount', () {
      // 9007199254740900 fen = 90071992547409.00 yuan exactly.
      expect(
        MoneyUtils.changeF2Y(9007199254740900, format: MoneyFormat.NORMAL),
        '90071992547409.00',
      );
    });

    test('END_INTEGER preserves whole-yuan value for huge amount', () {
      // amount % 100 == 0 → integer yuan. Must not lose precision via toDouble.
      expect(
        MoneyUtils.changeF2Y(
          9007199254740900,
          format: MoneyFormat.END_INTEGER,
        ),
        '90071992547409',
      );
      // amount % 10 == 0 (one decimal) keeps exact tenths.
      expect(
        MoneyUtils.changeF2Y(
          9007199254740950,
          format: MoneyFormat.END_INTEGER,
        ),
        '90071992547409.5',
      );
    });

    test('YUAN_INTEGER preserves whole-yuan value for huge amount', () {
      expect(
        MoneyUtils.changeF2Y(
          9007199254740900,
          format: MoneyFormat.YUAN_INTEGER,
        ),
        '90071992547409',
      );
    });

    test('normal small amounts unchanged (regression)', () {
      expect(MoneyUtils.changeF2Y(0), '0.00');
      expect(MoneyUtils.changeF2Y(123), '1.23');
      expect(MoneyUtils.changeF2Y(600), '6.00');
      expect(MoneyUtils.changeF2Y(600, format: MoneyFormat.END_INTEGER), '6');
      expect(
        MoneyUtils.changeF2Y(650, format: MoneyFormat.END_INTEGER),
        '6.5',
      );
      expect(
        MoneyUtils.changeF2Y(658, format: MoneyFormat.END_INTEGER),
        '6.58',
      );
      expect(
        MoneyUtils.changeF2Y(600, format: MoneyFormat.YUAN_INTEGER),
        '6',
      );
      expect(
        MoneyUtils.changeF2Y(658, format: MoneyFormat.YUAN_INTEGER),
        '6.58',
      );
    });
  });

  group('B3 withUnit enum exhaustiveness', () {
    test('NORMAL returns the money text unchanged', () {
      expect(MoneyUtils.withUnit('6.00', MoneyUnit.NORMAL), '6.00');
    });

    test('YUAN prepends the symbol', () {
      expect(MoneyUtils.withUnit('6.00', MoneyUnit.YUAN), '¥6.00');
    });

    test('YUAN_ZH appends 元', () {
      expect(MoneyUtils.withUnit('6.00', MoneyUnit.YUAN_ZH), '6.00元');
    });

    test('DOLLAR prepends the symbol', () {
      expect(MoneyUtils.withUnit('6.00', MoneyUnit.DOLLAR), '\$6.00');
    });

    test('changeF2YWithUnit normal case preserved (regression)', () {
      expect(
        MoneyUtils.changeF2YWithUnit(123, unit: MoneyUnit.YUAN),
        '¥1.23',
      );
      expect(
        MoneyUtils.changeF2YWithUnit(123, unit: MoneyUnit.NORMAL),
        '1.23',
      );
    });
  });
}
