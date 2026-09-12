// Wave B — medium-severity fixes for `num/num_utils.dart` (B1).
//
// B1 is a documentation change (no behavior change): the `*Num` methods
// route `num` operands through `a.toString()`, so an already-computed
// double like `0.1 + 0.2` (whose value is `0.30000000000000004`) is
// parsed at its *display* value. The precise `*DecString` API — which
// takes string operands directly — avoids that entirely.
//
// This test pins that contract: `addDecString('0.1', '0.2')` yields the
// exact '0.3', whereas routing the already-computed double
// `0.1 + 0.2` through `addDec` carries the floating-point display drift.
// (0.1.0 起 `*Dec` / `*DecString` 公开签名返回十进制字符串，Decimal 已收回内部。)

import 'package:cutils/num/num_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B1 *Num precision caveat (documentation)', () {
    test('addDecString on string operands yields exact 0.3', () {
      // The precise string-entry API never touches a double, so there is
      // no display-value drift. This is the API the *Num dartdoc points
      // callers to when they need exactness.
      expect(NumUtils.addDecString('0.1', '0.2'), '0.3');
    });

    test('addDec on the already-computed double 0.1+0.2 carries drift', () {
      // Demonstrates the documented lossy path: `0.1 + 0.2` as a double
      // is 0.30000000000000004, and `(0.1+0.2).toString()` is that long
      // form — which is what addDec parses. Contrast with the exact
      // addDecString result above.
      const drifted = 0.1 + 0.2;
      expect(drifted.toString(), '0.30000000000000004');
      expect(NumUtils.addDec(drifted, 0).toString(), '0.30000000000000004');
    });

    test('multiplyDecString/divideDecString stay exact (regression)', () {
      expect(NumUtils.multiplyDecString('0.1', '0.2').toString(), '0.02');
      expect(NumUtils.divideDecString('1', '4').toString(), '0.25');
    });
  });
}
