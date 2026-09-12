// Wave E — high-severity bug fixes for `num/num_utils.dart` (E1, E2).
//
// Strict TDD: each group below was first observed to FAIL for the right
// reason on the unmodified code, then the minimal fix was applied under
// `lib/num/num_utils.dart` to turn it green. No public signatures were
// changed. All assertions are plain and synchronous — no real timers or
// `Future.delayed` — to keep the suite deterministic.

import 'package:cutils/num/num_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // -----------------------------------------------------------------
  // E1 — `addNum`/`subtractNum`/`multiplyNum`/`divideNum` (`*Num`)
  // previously routed through `Decimal.tryParse` and silently coerced
  // every parse failure to `0.0` via `?? 0.0`. That hid real misuse
  // (non-finite inputs whose `toString()` is `Infinity`/`NaN`, which
  // `Decimal.tryParse` rejects). Per spec §11 D2 the silent fallback is
  // forbidden; the `*Num` wrappers must surface the failure.
  //
  // Note: decimal 3.2.4 actually accepts scientific notation like
  // `"1e+21"`, so the original hypothesis (large `1e20` triggering the
  // fallback) does not reproduce on the resolved decimal version. The
  // genuine trigger is non-finite doubles. The fix is identical: stop
  // the silent `0.0` substitution.
  // -----------------------------------------------------------------
  group('E1 *Num silent 0.0 fallback', () {
    test('addNum throws on non-finite input instead of returning 0.0', () {
      expect(
        () => NumUtils.addNum(double.nan, 1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => NumUtils.addNum(double.infinity, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('subtractNum throws on non-finite input instead of returning 0.0', () {
      expect(
        () => NumUtils.subtractNum(double.nan, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('multiplyNum throws on non-finite input instead of returning 0.0', () {
      expect(
        () => NumUtils.multiplyNum(double.nan, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('divideNum throws on non-finite input instead of returning 0.0', () {
      expect(
        () => NumUtils.divideNum(double.nan, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('normal inputs still compute the Decimal-based sum (regression)', () {
      // 0.1 + 0.2 must not collapse to a silent 0.0; it yields the
      // precise Decimal sum converted back to double.
      expect(NumUtils.addNum(0.1, 0.2), closeTo(0.3, 1e-9));
      expect(NumUtils.subtractNum(0.3, 0.1), closeTo(0.2, 1e-9));
      expect(NumUtils.multiplyNum(0.1, 0.2), closeTo(0.02, 1e-9));
      expect(NumUtils.divideNum(1, 4), closeTo(0.25, 1e-9));
    });

    test('precise *Dec APIs still return null on unparseable input', () {
      // The precise API keeps its nullable contract (spec D2); only the
      // double-returning wrappers surface the failure.
      expect(NumUtils.addDec(double.nan, 1), isNull);
      expect(NumUtils.divideDec(double.infinity, 1), isNull);
    });
  });

  // -----------------------------------------------------------------
  // E2 — `divideDec` / `divideDecString` previously called
  // `.toDecimal()` without `scaleOnInfinitePrecision`, which threw on
  // non-terminating quotients like 1/3. The fix passes an explicit
  // scale so the precise API returns a finite `Decimal`.
  // -----------------------------------------------------------------
  group('E2 divideDec non-terminating quotient', () {
    test('divideDec(1, 3) returns a finite string (no throw)', () {
      final result = NumUtils.divideDec(1, 3)!;
      // Truncated to ~20 significant decimal places.
      expect(result, '0.33333333333333333333');
    });

    test("divideDecString('1','3') returns a finite string (no throw)", () {
      expect(NumUtils.divideDecString('1', '3'), '0.33333333333333333333');
    });

    test('terminating quotients are unchanged (regression)', () {
      expect(NumUtils.divideDec(1, 4)!.toString(), '0.25');
      expect(NumUtils.divideDec(10, 2)!.toString(), '5');
    });

    test('divide by zero still yields null (documented sentinel)', () {
      expect(NumUtils.divideDec(1, 0), isNull);
      expect(NumUtils.divideDecString('1', '0'), isNull);
    });
  });
}
