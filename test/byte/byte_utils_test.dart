// Byte module — absorbed (as capability, rewritten null-safe) from
// YCFlutterUtils `lib/byte/`.
//
// Strict TDD: this suite was written first and observed to fail with
// compile errors (module not present) before `lib/byte/byte_utils.dart`
// was implemented. Deviations from the source on purpose:
// - `fromReadable` rejects out-of-range values (hex > 0xFF, dec > 255)
//   and malformed tokens with a typed [ArgumentError] — the source
//   silently truncated via `Uint8List.fromList`.
// - `ByteWord` / `ByteDoubleWord` take an explicit [Endian] at
//   serialization time instead of hard-coding little-endian.

import 'dart:typed_data';

import 'package:cutils/byte/byte_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B1 fromReadable parses hex/dec readable strings', () {
    test('hex with spaces', () {
      expect(
          ByteUtils.fromReadable('01 02 ff'), Uint8List.fromList([1, 2, 255]));
    });

    test('hex with commas and 0x prefixes mixed', () {
      expect(
        ByteUtils.fromReadable('01,02, 0x10'),
        Uint8List.fromList([1, 2, 16]),
      );
    });

    test('uppercase hex digits accepted', () {
      expect(ByteUtils.fromReadable('FF'), Uint8List.fromList([255]));
    });

    test('dec radix parses decimal tokens', () {
      expect(
        ByteUtils.fromReadable('1 2 255', radix: Radix.dec),
        Uint8List.fromList([1, 2, 255]),
      );
    });

    test('empty or blank input yields an empty list', () {
      expect(ByteUtils.fromReadable(''), Uint8List.fromList([]));
      expect(ByteUtils.fromReadable('   '), Uint8List.fromList([]));
    });

    test('hex token above 0xFF throws ArgumentError (no silent truncation)',
        () {
      expect(
        () => ByteUtils.fromReadable('1ff'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('dec token above 255 throws ArgumentError', () {
      expect(
        () => ByteUtils.fromReadable('300', radix: Radix.dec),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('dec negative token throws ArgumentError (value range rejects it)',
        () {
      expect(
        () => ByteUtils.fromReadable('-1', radix: Radix.dec),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('malformed token throws ArgumentError', () {
      expect(() => ByteUtils.fromReadable('zz'), throwsA(isA<ArgumentError>()));
    });
  });

  group('B2 toReadable formats bytes', () {
    test('hex pads each byte to two lowercase digits', () {
      expect(
        ByteUtils.toReadable(Uint8List.fromList([1, 2, 255])),
        '01 02 ff',
      );
    });

    test('dec radix and custom separator', () {
      expect(
        ByteUtils.toReadable(Uint8List.fromList([1, 2, 255]),
            radix: Radix.dec, separator: ','),
        '1,2,255',
      );
    });

    test('empty list yields empty string', () {
      expect(ByteUtils.toReadable(Uint8List.fromList([])), '');
    });

    test('toReadable → fromReadable round-trips', () {
      final bytes = Uint8List.fromList([0, 1, 127, 128, 255]);
      expect(
        ByteUtils.fromReadable(ByteUtils.toReadable(bytes)),
        bytes,
      );
    });
  });

  group('B3 base64 conversion', () {
    test('base64 round-trip', () {
      final bytes = Uint8List.fromList([1, 2, 255, 0, 200]);
      final encoded = ByteUtils.toBase64(bytes);
      expect(ByteUtils.fromBase64(encoded), bytes);
    });
  });

  group('B4 clone / same', () {
    test('clone returns an independent copy', () {
      final origin = Uint8List.fromList([1, 2, 3]);
      final copy = ByteUtils.clone(origin);
      copy[0] = 9;
      expect(origin[0], 1);
      expect(copy, Uint8List.fromList([9, 2, 3]));
    });

    test('same compares length and content', () {
      expect(
        ByteUtils.same(
          Uint8List.fromList([1, 2]),
          Uint8List.fromList([1, 2]),
        ),
        isTrue,
      );
      expect(
        ByteUtils.same(
          Uint8List.fromList([1, 2]),
          Uint8List.fromList([1, 2, 3]),
        ),
        isFalse,
      );
      expect(
        ByteUtils.same(
          Uint8List.fromList([1, 2]),
          Uint8List.fromList([2, 1]),
        ),
        isFalse,
      );
      expect(
        ByteUtils.same(Uint8List.fromList([]), Uint8List.fromList([])),
        isTrue,
      );
    });
  });

  group('B5 extract / combine / insert / remove', () {
    test('extract takes a middle window', () {
      expect(
        ByteUtils.extract(
          origin: Uint8List.fromList([1, 2, 3, 4, 5]),
          indexStart: 1,
          length: 2,
        ),
        Uint8List.fromList([2, 3]),
      );
    });

    test('extract clamps negative start and overlong length', () {
      expect(
        ByteUtils.extract(
          origin: Uint8List.fromList([1, 2, 3]),
          indexStart: -1,
          length: 99,
        ),
        Uint8List.fromList([1, 2, 3]),
      );
    });

    test('extract beyond the end yields an empty list', () {
      expect(
        ByteUtils.extract(
          origin: Uint8List.fromList([1, 2]),
          indexStart: 5,
          length: 1,
        ),
        Uint8List.fromList([]),
      );
    });

    test('extract with non-positive length yields an empty list', () {
      expect(
        ByteUtils.extract(
          origin: Uint8List.fromList([1, 2, 3]),
          indexStart: 1,
          length: 0,
        ),
        Uint8List.fromList([]),
      );
    });

    test('combine concatenates without mutating inputs', () {
      final a = Uint8List.fromList([1]);
      final b = Uint8List.fromList([2, 3]);
      expect(ByteUtils.combine(a: a, b: b), Uint8List.fromList([1, 2, 3]));
      expect(a, Uint8List.fromList([1]));
      expect(b, Uint8List.fromList([2, 3]));
    });

    test('insert places bytes at index, clamped to bounds', () {
      final origin = Uint8List.fromList([1, 4]);
      expect(
        ByteUtils.insert(
          origin: origin,
          indexStart: 1,
          arrayInsert: Uint8List.fromList([2, 3]),
        ),
        Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(
        ByteUtils.insert(
          origin: origin,
          indexStart: 0,
          arrayInsert: Uint8List.fromList([9]),
        ),
        Uint8List.fromList([9, 1, 4]),
      );
      expect(
        ByteUtils.insert(
          origin: origin,
          indexStart: 99,
          arrayInsert: Uint8List.fromList([9]),
        ),
        Uint8List.fromList([1, 4, 9]),
      );
      expect(origin, Uint8List.fromList([1, 4]));
    });

    test('remove deletes a window, clamped to bounds', () {
      expect(
        ByteUtils.remove(
          origin: Uint8List.fromList([1, 2, 3, 4]),
          indexStart: 1,
          lengthRemove: 2,
        ),
        Uint8List.fromList([1, 4]),
      );
      expect(
        ByteUtils.remove(
          origin: Uint8List.fromList([1, 2, 3]),
          indexStart: 2,
          lengthRemove: 99,
        ),
        Uint8List.fromList([1, 2]),
      );
    });

    test('remove with non-positive length returns an independent copy', () {
      final origin = Uint8List.fromList([1, 2, 3]);
      final kept = ByteUtils.remove(
        origin: origin,
        indexStart: 1,
        lengthRemove: 0,
      );
      expect(kept, origin);
      expect(identical(kept, origin), isFalse);
    });
  });

  group('B6 ByteWord (16-bit)', () {
    test('high / low split', () {
      final word = ByteWord(0x1234);
      expect(word.high, 0x12);
      expect(word.low, 0x34);
    });

    test('bytes honor explicit endianness', () {
      expect(
        ByteWord(0x1234).bytes(),
        Uint8List.fromList([0x34, 0x12]),
      );
      expect(
        ByteWord(0x1234).bytes(endian: Endian.big),
        Uint8List.fromList([0x12, 0x34]),
      );
    });

    test('value above 0xFFFF throws ArgumentError', () {
      expect(() => ByteWord(0x10000), throwsA(isA<ArgumentError>()));
      expect(() => ByteWord(-1), throwsA(isA<ArgumentError>()));
    });

    test('toString renders 4-digit hex', () {
      expect(ByteWord(0x1234).toString(), '0x1234');
    });
  });

  group('B7 ByteDoubleWord (32-bit)', () {
    test('bytes honor explicit endianness', () {
      expect(
        ByteDoubleWord(0x11223344).bytes(),
        Uint8List.fromList([0x44, 0x33, 0x22, 0x11]),
      );
      expect(
        ByteDoubleWord(0x11223344).bytes(endian: Endian.big),
        Uint8List.fromList([0x11, 0x22, 0x33, 0x44]),
      );
    });

    test('value above 0xFFFFFFFF throws ArgumentError', () {
      expect(() => ByteDoubleWord(0x100000000), throwsA(isA<ArgumentError>()));
      expect(() => ByteDoubleWord(-1), throwsA(isA<ArgumentError>()));
    });
  });
}
