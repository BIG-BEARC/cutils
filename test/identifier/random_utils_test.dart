// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/identifier/random_utils.dart';

void main() {
  group('RandomUtils.randomColor', () {
    test('returns a fully-opaque ARGB int (0xFF000000..0xFFFFFFFF)', () {
      for (var i = 0; i < 100; i++) {
        final color = RandomUtils.randomColor();
        expect(color, greaterThanOrEqualTo(0xFF000000));
        expect(color, lessThanOrEqualTo(0xFFFFFFFF));
      }
    });

    test('hex form starts with FF (alpha channel)', () {
      final color = RandomUtils.randomColor();
      expect(color.toRadixString(16).padLeft(8, '0').substring(0, 2), 'ff');
    });
  });

  group('RandomUtils.randomString', () {
    test('explicit length is honored', () {
      expect(RandomUtils.randomString(length: 10).length, 10);
      expect(RandomUtils.randomString(length: 1).length, 1);
    });

    test('chars stay in the documented 89..121 ASCII window', () {
      final s = RandomUtils.randomString(length: 500);
      for (final rune in s.runes) {
        expect(rune, greaterThanOrEqualTo(89));
        expect(rune, lessThanOrEqualTo(121));
      }
    });

    test('random length falls in [0, 1024) when omitted', () {
      for (var i = 0; i < 20; i++) {
        final length = RandomUtils.randomString().length;
        expect(length, greaterThanOrEqualTo(0));
        expect(length, lessThan(1024));
      }
    });
  });

  group('RandomUtils whitespace helpers', () {
    test('condenseWhiteSpace collapses runs and trims', () {
      expect(RandomUtils.condenseWhiteSpace('  a   b \n\t c  '), 'a b c');
    });

    test('removeWhiteSpace strips every whitespace char', () {
      expect(RandomUtils.removeWhiteSpace(' a\tb\nc '), 'abc');
    });

    test('isWhiteSpaceOrEmptyOrNull matches null/empty/blank only', () {
      expect(RandomUtils.isWhiteSpaceOrEmptyOrNull(null), isTrue);
      expect(RandomUtils.isWhiteSpaceOrEmptyOrNull(''), isTrue);
      expect(RandomUtils.isWhiteSpaceOrEmptyOrNull('   '), isTrue);
      expect(RandomUtils.isWhiteSpaceOrEmptyOrNull('a b'), isFalse);
    });
  });

  group('RandomUtils.removeNonDigits', () {
    test('keeps only digit chars', () {
      expect(RandomUtils.removeNonDigits('a1b22c333'), '122333');
      expect(RandomUtils.removeNonDigits('手机号13800138000'), '13800138000');
      expect(RandomUtils.removeNonDigits('abc'), '');
    });
  });

  group('RandomUtils.randInt', () {
    test('default start=0 keeps results within [0, end)', () {
      for (var i = 0; i < 200; i++) {
        final v = RandomUtils.randInt(10);
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(10));
      }
    });

    test('explicit start shifts the window to [start, start+end)', () {
      for (var i = 0; i < 200; i++) {
        final v = RandomUtils.randInt(10, start: 5);
        expect(v, greaterThanOrEqualTo(5));
        expect(v, lessThan(15));
      }
    });

    test('end=1 always yields start', () {
      expect(RandomUtils.randInt(1, start: 7), 7);
    });
  });

  group('RandomUtils.randomElement', () {
    test('empty list returns null', () {
      expect(RandomUtils.randomElement<int>([]), isNull);
    });

    test('result is always a member of the list', () {
      const items = [1, 2, 3, 4, 5];
      for (var i = 0; i < 100; i++) {
        expect(items, contains(RandomUtils.randomElement(items)));
      }
    });
  });
}
