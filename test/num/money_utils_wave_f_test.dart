// Wave F — absorb `changeY2F` (yuan → fen) into `num/money_utils.dart`.
//
// Strict TDD: this suite was written first and observed to fail with
// compile errors (`changeY2F` not defined) before the implementation
// was added. The conversion goes through `Decimal` (`Decimal.parse` +
// `shift(2)`) rather than `double`, so fen values near and beyond the
// 2^53 double boundary stay exact. Sub-fen amounts (more than two
// decimal places) are rejected with a typed [ArgumentError] instead of
// being silently truncated. All assertions are synchronous.

import 'package:cutils/num/money_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1 changeY2F basic conversion', () {
    test('decimal yuan converts to exact fen', () {
      expect(MoneyUtils.changeY2F('1.23'), 123);
    });

    test('integer yuan string converts to fen', () {
      expect(MoneyUtils.changeY2F('100'), 10000);
    });

    test('one-decimal yuan pads to fen', () {
      expect(MoneyUtils.changeY2F('0.1'), 10);
    });

    test('negative yuan converts to negative fen', () {
      expect(MoneyUtils.changeY2F('-1.23'), -123);
    });

    test('zero yuan converts to zero fen', () {
      expect(MoneyUtils.changeY2F('0'), 0);
    });

    test('fen value beyond the 2^53 double boundary stays exact', () {
      // 9007199254740993 yuan → 900719925474099300 fen. This fits int64
      // but a double round-trip would corrupt it; Decimal must not.
      expect(MoneyUtils.changeY2F('9007199254740993'), 900719925474099300);
    });
  });

  group('F2 changeY2F error semantics', () {
    test('sub-fen amount throws a typed ArgumentError (no silent truncation)',
        () {
      expect(
        () => MoneyUtils.changeY2F('1.234'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('empty string throws a typed ArgumentError', () {
      expect(
        () => MoneyUtils.changeY2F(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('non-numeric string throws a typed ArgumentError', () {
      expect(
        () => MoneyUtils.changeY2F('abc'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fen value beyond the platform int range throws (no silent clamping)',
        () {
      // 2^63 fen exactly — BigInt.toInt() would clamp this to int64 max;
      // the isValidInt guard must surface it as an error instead.
      expect(
        () => MoneyUtils.changeY2F('92233720368547758.08'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
