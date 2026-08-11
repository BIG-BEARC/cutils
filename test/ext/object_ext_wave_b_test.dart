// Wave B — medium-severity fix for `ext/object_ext.dart` (B8).
//
// B8: `isNullOrBlank` treated `0` (any `num == 0`) as blank, which is
// surprising — `0` is a valid value. The `num` branch is removed so
// numbers are never blank. The dead `this is! bool` guard (bool is not
// a subtype of num) is deleted with it. BREAKING: callers that relied
// on `0` being blank must now check explicitly.

import 'package:cutils/ext/object_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B8 isNullOrBlank no longer treats 0 as blank', () {
    test('integer 0 is NOT blank (BREAKING)', () {
      final int v = 0;
      expect(v.isNullOrBlank(), isFalse);
    });

    test('double 0.0 is NOT blank (BREAKING)', () {
      final double v = 0.0;
      expect(v.isNullOrBlank(), isFalse);
    });

    test('non-zero number is not blank', () {
      expect(42.isNullOrBlank(), isFalse);
      expect(3.14.isNullOrBlank(), isFalse);
    });

    test('null is blank', () {
      final Object? v = null;
      expect(v.isNullOrBlank(), isTrue);
    });

    test('empty string is blank', () {
      expect(''.isNullOrBlank(), isTrue);
    });

    test('non-empty string is not blank', () {
      expect('x'.isNullOrBlank(), isFalse);
    });

    test('empty iterable/map are blank (regression)', () {
      expect([].isNullOrBlank(), isTrue);
      expect(<String, int>{}.isNullOrBlank(), isTrue);
    });

    test('non-empty iterable/map are not blank (regression)', () {
      expect([1].isNullOrBlank(), isFalse);
      expect(<String, int>{'a': 1}.isNullOrBlank(), isFalse);
    });

    test('bool is not blank (dead bool check removed)', () {
      expect(false.isNullOrBlank(), isFalse);
      expect(true.isNullOrBlank(), isFalse);
    });
  });
}
