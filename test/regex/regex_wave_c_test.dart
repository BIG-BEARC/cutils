// Wave C — high-severity bug fixes for `regex`.
//
// Strict TDD: each group below was first observed to FAIL for the right
// reason on the unmodified code, then the minimal fix was applied under
// `lib/regex/` to turn it green.
//
// C1 & C4 change the *semantics* of public constants (breaking, spec §11 D5):
//   - REGEX_INTEGER/REGEX_FLOAT family: now fully anchored — strings with
//     trailing/leading garbage (e.g. "123abc") are no longer accepted.
//   - REGEX_EMAIL: replaced with a non-backtracking form and a 254-char cap;
//     intentionally more permissive about local-part characters.
//
// Note on C4 ReDoS: Dart's RegExp engine (Irregexp) does not exhibit
// catastrophic backtracking on the OLD `REGEX_EMAIL` pattern for any input we
// tried — the `[-+.]` separators remove partition ambiguity, so the classic
// `\w+([-+.]\w+)*` blowup does not trigger (confirmed against an engine that
// DOES backtrack: `(a+)+$`, n=26 → ~1.5s). The RED driver for C4 is therefore
// the *behavioral* change (more permissive local part + length cap), not a
// timing failure. The stopwatch assertion below is kept as a regression guard.

import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/regex/regex_constants.dart';
import 'package:cutils/regex/regex_utils.dart';

void main() {
  // -------------------------------------------------------------------
  // C1 — numeric regexes are not anchored across alternations.
  //
  // The bug: in patterns like `^(-?[1-9]\d*)|0$` the `^` binds only to the
  // first alternative and `$` only to the last, so `hasMatch("123abc")`
  // returns true (it matches the `^(-?[1-9]\d*)` prefix). We test the
  // constants directly because the public contract of a `REGEX_*` constant is
  // `RegExp(constant).hasMatch(input)`; the higher-level `isInteger` helpers
  // use separate, already-correct inline patterns.
  // -------------------------------------------------------------------
  group('C1 numeric regex anchoring', () {
    test('REGEX_INTEGER rejects trailing/leading garbage', () {
      expect(RegExp(RegexConstants.REGEX_INTEGER).hasMatch('123abc'), isFalse,
          reason: '"123abc" must NOT be accepted as an integer');
      expect(RegExp(RegexConstants.REGEX_INTEGER).hasMatch('0'), isTrue);
      expect(RegExp(RegexConstants.REGEX_INTEGER).hasMatch('-42'), isTrue);
      expect(RegExp(RegexConstants.REGEX_INTEGER).hasMatch('01'), isFalse);
    });

    test('REGEX_NOT_NEGATIVE_INTEGER is fully anchored', () {
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_INTEGER).hasMatch('10x'),
          isFalse,
          reason: 'trailing garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_INTEGER).hasMatch('00'),
          isFalse,
          reason: '"00" must be rejected — only a bare "0" is allowed');
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_INTEGER).hasMatch('0'),
          isTrue);
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_INTEGER).hasMatch('42'),
          isTrue);
    });

    test('REGEX_NOT_POSITIVE_INTEGER is fully anchored', () {
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_INTEGER).hasMatch('-5x'),
          isFalse,
          reason: 'trailing garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_INTEGER).hasMatch('0abc'),
          isFalse,
          reason: 'trailing garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_INTEGER).hasMatch('-5'),
          isTrue);
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_INTEGER).hasMatch('0'),
          isTrue);
    });

    test('REGEX_FLOAT stays correct (already anchored, regression guard)', () {
      expect(RegExp(RegexConstants.REGEX_FLOAT).hasMatch('1.23'), isTrue);
      expect(RegExp(RegexConstants.REGEX_FLOAT).hasMatch('1.2.3'), isFalse);
      expect(RegExp(RegexConstants.REGEX_FLOAT).hasMatch('-0.5'), isTrue);
      expect(RegExp(RegexConstants.REGEX_FLOAT).hasMatch('0'), isTrue);
      expect(RegExp(RegexConstants.REGEX_FLOAT).hasMatch('1.5x'), isFalse);
    });

    test('REGEX_POSITIVE_FLOAT is fully anchored', () {
      expect(
          RegExp(RegexConstants.REGEX_POSITIVE_FLOAT).hasMatch('1.5x'), isFalse,
          reason: 'trailing garbage must be rejected');
      expect(
          RegExp(RegexConstants.REGEX_POSITIVE_FLOAT).hasMatch('x0.5'), isFalse,
          reason: 'leading garbage must be rejected');
      expect(
          RegExp(RegexConstants.REGEX_POSITIVE_FLOAT).hasMatch('1.5'), isTrue);
      expect(
          RegExp(RegexConstants.REGEX_POSITIVE_FLOAT).hasMatch('0.5'), isTrue);
    });

    test('REGEX_NEGATIVE_FLOAT is fully anchored', () {
      expect(RegExp(RegexConstants.REGEX_NEGATIVE_FLOAT).hasMatch('-1.5x'),
          isFalse,
          reason: 'trailing garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NEGATIVE_FLOAT).hasMatch('abc-0.5'),
          isFalse,
          reason: 'leading garbage must be rejected');
      expect(
          RegExp(RegexConstants.REGEX_NEGATIVE_FLOAT).hasMatch('-1.5'), isTrue);
      expect(
          RegExp(RegexConstants.REGEX_NEGATIVE_FLOAT).hasMatch('-0.5'), isTrue);
    });

    test('REGEX_NOT_NEGATIVE_FLOAT is fully anchored', () {
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_FLOAT).hasMatch('1.5x'),
          isFalse,
          reason: 'trailing garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_FLOAT).hasMatch('x0.5'),
          isFalse,
          reason: 'leading garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_FLOAT).hasMatch('1.5'),
          isTrue);
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_FLOAT).hasMatch('0.5'),
          isTrue);
      expect(RegExp(RegexConstants.REGEX_NOT_NEGATIVE_FLOAT).hasMatch('0'),
          isTrue);
    });

    test('REGEX_NOT_POSITIVE_FLOAT is fully anchored', () {
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_FLOAT).hasMatch('x-1.5'),
          isFalse,
          reason: 'leading garbage must be rejected');
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_FLOAT).hasMatch('-1.5'),
          isTrue);
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_FLOAT).hasMatch('0'),
          isTrue);
      expect(RegExp(RegexConstants.REGEX_NOT_POSITIVE_FLOAT).hasMatch('0.0'),
          isTrue);
    });
  });

  // -------------------------------------------------------------------
  // C2 — ID-card regex uses [0|1|2]; inside a character class `|` is a
  // literal, so the day-tens slot wrongly accepts `|`.
  // -------------------------------------------------------------------
  group('C2 id-card [0|1|2] character class', () {
    // 15-digit carrier built so every slot satisfies the regex EXCEPT the
    // day-tens position, which is `|`:
    //   `[1-9]`          -> "1"
    //   `\d{7}`          -> "1010101"
    //   month `(0\d|1[0-2])` -> "06"
    //   day   `([0|1|2]\d|3[0-1])` -> "|5"  (matches ONLY on buggy code)
    //   seq `\d{3}`      -> "001"
    const buggy15 = '1101010106|5001';

    test('REGEX_ID_CARD15 rejects a pipe in the day-tens slot', () {
      expect(RegExp(RegexConstants.REGEX_ID_CARD15).hasMatch(buggy15), isFalse,
          reason: '`|` must not be accepted where only 0/1/2 is valid');
    });

    test('regexIdCard15 (lowercase alias) rejects a pipe in the day-tens slot',
        () {
      expect(RegExp(RegexConstants.regexIdCard15).hasMatch(buggy15), isFalse,
          reason: 'lowercase alias must agree with the uppercase constant');
    });

    test('REGEX_ID_CARD18 rejects a pipe in the day-tens slot', () {
      // 18-digit carrier: province(6) + year(4) + month(2) + day(2) + seq(3) + check(1).
      //   `[1-9]\d{5}`      -> "110101"
      //   `[1-9]\d{3}`      -> "1990"
      //   month             -> "06"
      //   day `([0|1|2]\d)` -> "|5"  (matches ONLY on buggy code)
      //   seq `\d{3}`       -> "001"
      //   check `[0-9Xx]`   -> "X"
      const buggy18 = '110101199006|5001X';
      expect(RegExp(RegexConstants.REGEX_ID_CARD18).hasMatch(buggy18), isFalse,
          reason: '`|` must not be accepted where only 0/1/2 is valid');
    });
  });

  // -------------------------------------------------------------------
  // C3 — id-card checksum rejects a lowercase trailing `x`.
  // -------------------------------------------------------------------
  group('C3 id-card lowercase trailing x', () {
    // 11010519491231002X is a known-valid 18-digit id (checksum = X,
    // province 11 = 北京). The lowercase form must also validate.
    const upper = '11010519491231002X';
    const lower = '11010519491231002x';

    test('reference uppercase id validates', () {
      expect(RegexUtils.isIDCard18Exact(upper), isTrue);
    });

    test('lowercase trailing x validates (RED on old code)', () {
      expect(RegexUtils.isIDCard18Exact(lower), isTrue,
          reason: 'lowercase `x` is permitted by [0-9Xx] and must checksum OK');
    });

    test('isIDCard dispatches the lowercase form correctly', () {
      expect(RegexUtils.isIDCard(lower), isTrue);
    });
  });

  // -------------------------------------------------------------------
  // C4 — email regex: ReDoS guard + non-backtracking pattern + length cap.
  // -------------------------------------------------------------------
  group('C4 email regex', () {
    test('normal valid emails pass', () {
      expect(RegexUtils.isEmail('a.b@x.com'), isTrue);
      expect(RegexUtils.isEmail('user.name+tag@example.co.uk'), isTrue);
    });

    test('clearly-invalid inputs are rejected', () {
      expect(RegexUtils.isEmail('abc'), isFalse);
      expect(RegexUtils.isEmail(''), isFalse);
      expect(RegexUtils.isEmail('no-at-sign.com'), isFalse);
      expect(RegexUtils.isEmail('a@b'), isFalse); // no dot in domain
    });

    test('local part is intentionally permissive (RED on old code)', () {
      // The old `\w+([-+.]\w+)*` local part forbids `!`; the new
      // `[^\s@]+` form accepts it. The new pattern is intentionally MORE
      // permissive — see commit message.
      expect(RegexUtils.isEmail('a!b@c.com'), isTrue);
    });

    test('inputs longer than 254 chars are rejected (RED on old code)', () {
      // RFC 5321 caps the total length of an email address at 254 octets.
      final longLocal = 'a' * 250;
      final tooLong = '$longLocal@b.co'; // 250 + 1 + 4 = 255 chars
      expect(tooLong.length, greaterThan(254));
      expect(RegexUtils.isEmail(tooLong), isFalse);
    });

    test('ReDoS guard: pathological input is rejected QUICKLY (regression)',
        () {
      // A long, dot-separated local part with no `@`. On a backtracking
      // engine this pattern family (`\w+([-+.]\w+)*`) is exponential; the
      // new pattern is linear. We assert < 100ms regardless.
      final buf = StringBuffer('a' * 8);
      for (int i = 0; i < 30; i++) {
        buf.write('.');
        buf.write('a' * 8);
      }
      final input = buf.toString();
      expect(input.contains('@'), isFalse);

      final sw = Stopwatch()..start();
      final result = RegexUtils.isEmail(input);
      sw.stop();
      developer.log(
        'C4 ReDoS guard: len=${input.length} ms=${sw.elapsedMilliseconds}',
        name: 'cutils.regex.wave_c',
      );
      expect(result, isFalse);
      expect(sw.elapsedMilliseconds, lessThan(100),
          reason: 'must not exhibit catastrophic backtracking');
    });
  });
}
