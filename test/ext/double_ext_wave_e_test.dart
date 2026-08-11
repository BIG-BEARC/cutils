// Wave E — high-severity bug fix for `ext/double_ext.dart` (E4).
//
// Strict TDD: the failing path was first observed to mis-handle the
// leading `-` of negative numbers in `thousandSeparated` (the sign was
// treated as a digit group, yielding output like `-,100.00`), then the
// minimal fix was applied: strip the sign, format the magnitude, then
// prepend `-` if negative. Existing positive/decimal behavior is
// preserved (the method still forces 2 decimals via
// `toStringAsFixed(2)`). All assertions are synchronous — no timers —
// to keep the suite deterministic.

import 'package:cutils/ext/double_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E4 thousandSeparated negative numbers', () {
    test('negative thousand has sign before the first group', () {
      expect((-1000.0).thousandSeparated, '-1,000.00');
    });

    test('negative million formats groups correctly', () {
      expect((-1000000.0).thousandSeparated, '-1,000,000.00');
    });

    test('small negative keeps the sign with no grouping', () {
      expect((-123.0).thousandSeparated, '-123.00');
    });

    test('positive cases are unchanged (regression)', () {
      expect(1234.0.thousandSeparated, '1,234.00');
      expect(1000000.0.thousandSeparated, '1,000,000.00');
      expect(0.0.thousandSeparated, '0.00');
    });

    test('decimal values still forced to 2 decimals (regression)', () {
      expect(1234.5.thousandSeparated, '1,234.50');
      expect((-1234.5).thousandSeparated, '-1,234.50');
    });
  });
}
