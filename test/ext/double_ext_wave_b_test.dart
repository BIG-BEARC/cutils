// Wave B — medium-severity fix for `ext/double_ext.dart` (B7).
//
// B7: `double_ext.percentFormat` did NOT multiply by 100 while the
// same-named `int_ext.percentFormat` did — same name, different
// semantics. Unified to multiply by 100 so `0.25.percentFormat()` →
// `"25%"`. BREAKING: previous output for `0.25.percentFormat()` was
// `"0.25%"`.

import 'package:cutils/ext/double_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B7 percentFormat multiplies by 100', () {
    test('0.25 → "25%"', () {
      expect(0.25.percentFormat(), '25%');
    });

    test('0.5 → "50%"', () {
      expect(0.5.percentFormat(), '50%');
    });

    test('0.0 → "0%"', () {
      expect(0.0.percentFormat(), '0%');
    });

    test('1.0 → "100%"', () {
      expect(1.0.percentFormat(), '100%');
    });

    test('null → "0%"', () {
      double? nil;
      expect(nil.percentFormat(), '0%');
    });

    test('fractional percent keeps its non-zero digits', () {
      // 0.125 * 100 = 12.5 → "12.5%".
      expect(0.125.percentFormat(), '12.5%');
    });

    test('explicit fractionDigits bounds the precision', () {
      // 0.123456 * 100 = 12.3456 → fractionDigits=2 → "12.35%".
      expect(0.123456.percentFormat(2), '12.35%');
    });
  });
}
