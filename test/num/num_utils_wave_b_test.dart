// Wave B — medium-severity fixes for `num/num_utils.dart` (B1).
//
// B1 is a documentation change (no behavior change): the `*Num` methods
// route `num` operands through `a.toString()`, so an already-computed
// double like `0.1 + 0.2` (whose value is `0.30000000000000004`) is
// parsed at its *display* value. The precise `*DecString` API — which
// takes string operands directly — avoids that entirely.
//
// This test pins that contract: `addDecString('0.1', '0.2')` yields the
// exact `Decimal(0.3)`, whereas routing the already-computed double
// `0.1 + 0.2` through `addDec` carries the floating-point display drift.

import 'package:cutils/num/num_utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B1 *Num precision caveat (documentation)', () {
    test('addDecString on string operands yields exact Decimal(0.3)', () {
      // The precise string-entry API never touches a double, so there is
      // no display-value drift. This is the API the *Num dartdoc points
      // callers to when they need exactness.
      expect(NumUtils.addDecString('0.1', '0.2').toString(), '0.3');
      expect(NumUtils.addDecString('0.1', '0.2'), Decimal.parse('0.3'));
    });

    test('addDec on the already-computed double 0.1+0.2 carries drift', () {
      // Demonstrates the documented lossy path: `0.1 + 0.2` as a double
      // is 0.30000000000000004, and `(0.1+0.2).toString()` is that long
      // form — which is what addDec parses. Contrast with the exact
      // addDecString result above.
      final drifted = 0.1 + 0.2;
      expect(drifted.toString(), '0.30000000000000004');
      expect(NumUtils.addDec(drifted, 0).toString(), '0.30000000000000004');
    });

    test('multiplyDecString/divideDecString stay exact (regression)', () {
      expect(NumUtils.multiplyDecString('0.1', '0.2').toString(), '0.02');
      expect(NumUtils.divideDecString('1', '4').toString(), '0.25');
    });
  });
}
