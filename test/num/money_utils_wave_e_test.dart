// Wave E — high-severity bug fix for `num/money_utils.dart` (E3).
//
// Strict TDD: the failing path was first observed to throw a bare
// `FormatException` from `int.parse` inside `changeFStr2YWithUnit`, then
// the minimal fix was applied so the failure surfaces as a typed
// [ArgumentError] with a clear message. The normal path is unchanged.
//
// Note: the actual `int.parse(amountStr)` call lives in
// `changeFStr2YWithUnit` (the string-entry variant). `changeF2Y` itself
// takes an `int`, so the spec's `changeF2Y('')` shorthand maps onto the
// string-based method tested here. All assertions are synchronous — no
// timers — to keep the suite deterministic.

import 'package:cutils/num/money_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E3 changeFStr2YWithUnit malformed input', () {
    test('empty string throws a typed ArgumentError (not bare FormatException)',
        () {
      expect(
        () => MoneyUtils().changeFStr2YWithUnit(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('non-numeric string throws a typed ArgumentError', () {
      expect(
        () => MoneyUtils().changeFStr2YWithUnit('abc'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('overflowing string throws a typed ArgumentError', () {
      // A value far beyond int64 range; must not leak a bare
      // `FormatException`/`IntegerDivisionByZeroException`.
      expect(
        () => MoneyUtils().changeFStr2YWithUnit('99999999999999999999999999'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('normal fen string still converts (regression)', () {
      expect(MoneyUtils().changeFStr2YWithUnit('123'), '1.23');
      expect(MoneyUtils().changeFStr2YWithUnit('0'), '0.00');
    });
  });
}
