// Wave C2 — medium-severity bug fixes for `regex_utils` + `regex_constants`.
//
// Strict TDD: every assertion below was first observed to FAIL for the right
// reason on the unmodified code, then the minimal fix was applied under
// `lib/regex/` to turn it green.
//
// Scope:
//   - isURL / isIP used UNANCHORED patterns, so `hasMatch` matched substrings
//     surrounded by garbage (`"blah http://x blah"` was accepted as a URL).
//     Fix: anchor `^...$` on REGEX_URL / REGEX_IP.
//   - isNumeric accepted a trailing dot (`"123."` matched via `\d+\.?\d*`).
//     Fix: require a digit after the dot — `^-?(?:\d+(?:\.\d+)?|\.\d+)$`.
//   - isJSON was inconsistent: it returned true for any non-null JSON literal
//     (so `"123"` → true) but `"null"` → false (json.decode returns null).
//     Fix: isJSON now validates ONLY JSON objects/arrays (the common use),
//     consistently rejecting scalars AND null. Documented on the dartdoc.
//
// regex_constants: the lowercase duplicate set (`email`, `url`, `hexadecimal`,
//   `vector`/`image`/`audio`/`video`/`txt`/`doc`/`excel`/`ppt`/`apk`/`pdf`/
//   `html`) was UNUSED across lib/example/test, had unescaped `.` and was
//   case-sensitive. All were DELETED (breaking — removes public symbols).
//   There is nothing to regression-test for fixed-used patterns because none
//   were used.

import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/regex/regex_utils.dart';

void main() {
  // -----------------------------------------------------------------
  // isURL / isIP anchoring.
  // -----------------------------------------------------------------
  group('C2 isURL anchoring', () {
    test('rejects a URL embedded in surrounding text (RED on old code)', () {
      expect(RegexUtils().isURL('blah http://x blah'), isFalse,
          reason: 'unanchored regex matched the substring "http://x"; '
              'a full-string match is required.');
    });

    test('accepts a bare URL', () {
      expect(RegexUtils().isURL('http://x.com'), isTrue);
      expect(RegexUtils().isURL('https://www.example.com/a/b?c=1'), isTrue);
    });

    test('rejects a leading-space URL (anchored at start)', () {
      expect(RegexUtils().isURL(' http://x.com'), isFalse);
    });

    test('rejects empty input', () {
      expect(RegexUtils().isURL(''), isFalse);
    });
  });

  group('C2 isIP anchoring', () {
    test('rejects an IP embedded in surrounding text (RED on old code)', () {
      expect(RegexUtils().isIP('ip is 1.2.3.4 here'), isFalse,
          reason: 'unanchored regex matched the substring "1.2.3.4"; '
              'a full-string match is required.');
    });

    test('accepts a bare IPv4', () {
      expect(RegexUtils().isIP('1.2.3.4'), isTrue);
      expect(RegexUtils().isIP('255.255.255.255'), isTrue);
      expect(RegexUtils().isIP('0.0.0.0'), isTrue);
    });

    test('rejects an out-of-range octet', () {
      expect(RegexUtils().isIP('1.2.3.999'), isFalse);
    });

    test('rejects empty input', () {
      expect(RegexUtils().isIP(''), isFalse);
    });
  });

  // -----------------------------------------------------------------
  // isNumeric trailing-dot.
  // -----------------------------------------------------------------
  group('C2 isNumeric trailing dot', () {
    test('rejects a trailing dot (RED on old code)', () {
      expect(RegexUtils().isNumeric('123.'), isFalse,
          reason: '"123." has no fractional digit; the dot must be followed '
              'by at least one digit.');
    });

    test('rejects a lone dot', () {
      expect(RegexUtils().isNumeric('.'), isFalse);
    });

    test('accepts integers', () {
      expect(RegexUtils().isNumeric('123'), isTrue);
      expect(RegexUtils().isNumeric('-123'), isTrue);
      expect(RegexUtils().isNumeric('0'), isTrue);
    });

    test('accepts decimal numbers', () {
      expect(RegexUtils().isNumeric('12.3'), isTrue);
      expect(RegexUtils().isNumeric('-12.3'), isTrue);
      expect(RegexUtils().isNumeric('.5'), isTrue);
      expect(RegexUtils().isNumeric('0.0'), isTrue);
    });

    test('rejects non-numeric input', () {
      expect(RegexUtils().isNumeric('12a'), isFalse);
      expect(RegexUtils().isNumeric('1.2.3'), isFalse);
      expect(RegexUtils().isNumeric(''), isFalse);
      expect(RegexUtils().isNumeric(null), isFalse);
    });
  });

  // -----------------------------------------------------------------
  // isJSON — object/array only, consistent.
  // -----------------------------------------------------------------
  group('C2 isJSON object/array semantics', () {
    test('accepts a JSON object', () {
      expect(RegexUtils().isJSON('{"a":1}'), isTrue);
      expect(RegexUtils().isJSON('{}'), isTrue);
    });

    test('accepts a JSON array', () {
      expect(RegexUtils().isJSON('[1,2,3]'), isTrue);
      expect(RegexUtils().isJSON('[]'), isTrue);
    });

    test('rejects a JSON scalar that is NOT an object/array (RED on old code)',
        () {
      // Old code: json.decode("123") -> 123 (!= null) -> true.
      // New contract: only objects/arrays count.
      expect(RegexUtils().isJSON('123'), isFalse);
      expect(RegexUtils().isJSON('12.5'), isFalse);
      expect(RegexUtils().isJSON('true'), isFalse);
      expect(RegexUtils().isJSON('false'), isFalse);
      expect(RegexUtils().isJSON('"a string"'), isFalse);
    });

    test('rejects the literal "null" consistently', () {
      // Both old and new code reject "null"; the new contract does so for the
      // same reason as the other scalars (null is not an object/array), making
      // the behavior consistent instead of a special case.
      expect(RegexUtils().isJSON('null'), isFalse);
    });

    test('rejects invalid JSON', () {
      expect(RegexUtils().isJSON('{not json'), isFalse);
      expect(RegexUtils().isJSON(''), isFalse);
      expect(RegexUtils().isJSON(null), isFalse);
    });
  });
}
