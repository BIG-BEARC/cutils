// Dart imports:
import 'dart:io';

// Package imports:
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/crypto/crypto_utils.dart';

/// Wave G — crypto 高危修复回归测试。
void main() {
  final tempDir = Directory('${Directory.systemTemp.path}/cutils_crypto_test')
    ..createSync(recursive: true);

  group('G1: encodeMd5File binary-safe hash', () {
    test('hashes raw bytes (non-ASCII) matching md5 of the raw bytes', () {
      // 0xFF / 0x80 are invalid as standalone UTF-8 start bytes, so the old
      // readAsStringSync() path corrupts (or throws). The hash must match the
      // md5 computed independently over the raw bytes.
      final bytes = <int>[0xFF, 0x00, 0x7F, 0x80, 0xC2, 0xA9];
      final file = File('${tempDir.path}/g1_binary.bin')
        ..writeAsBytesSync(bytes);

      final hash = CryptoUtils.encodeMd5File(file);
      final expected = md5.convert(bytes).toString();

      expect(hash, equals(expected));
    });

    test('hash of plain ASCII text matches encodeMd5', () {
      const content = 'hello md5';
      final file = File('${tempDir.path}/g1_ascii.txt')
        ..writeAsStringSync(content);

      final hash = CryptoUtils.encodeMd5File(file);
      expect(hash, equals(CryptoUtils.encodeMd5(content)));
    });
  });

  group('G2: xorCode validation + xorBase64 round-trip', () {
    test('xorBase64Encode/Decode round-trip for common input', () {
      const key = '1,2,3';
      const input = 'hello world 你好 flutter';
      final encoded = CryptoUtils.xorBase64Encode(input, key);
      final decoded = CryptoUtils.xorBase64Decode(encoded, key);
      expect(decoded, equals(input));
    });

    test('xorBase64Encode/Decode round-trip survives XOR into surrogate range',
        () {
      // Under the old code-unit path: 'A'(65) ^ 55361 = 0xD800 (an unpaired
      // surrogate). String.fromCharCodes yields ill-formed UTF-16 and the
      // subsequent utf8.encode in encodeBase64 throws. The byte-level fix
      // round-trips cleanly.
      const key = '55361';
      const input = 'A';
      final encoded = CryptoUtils.xorBase64Encode(input, key);
      final decoded = CryptoUtils.xorBase64Decode(encoded, key);
      expect(decoded, equals(input));
    });

    test('xorCode throws a typed ArgumentError on non-integer key segment', () {
      // Before the fix a bare FormatException leaked out of int.parse.
      expect(
        () => CryptoUtils.xorCode('abc', 'not,an,int,key'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('xorBase64Encode throws a typed ArgumentError on bad key', () {
      expect(
        () => CryptoUtils.xorBase64Encode('abc', '1,bad,3'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
