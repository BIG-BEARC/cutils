// SHA-256 / HMAC — absorbed (as capability) from saas_pos_smart_edition
// `lib/core/utils/crypt_utils.dart`.
//
// Strict TDD: written first. Expected values are standard test vectors
// (FIPS 180 for SHA-256; the Wikipedia/RFC "quick brown fox" vector for
// HMAC), so they do not depend on the implementation under test. The
// base64 expectations are derived from those same vectors via the Dart
// SDK's own hex/base64 codecs.

import 'dart:convert';

import 'package:cutils/crypto/crypto_utils.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('H1 encodeSha256（hex 小写，对齐 encodeMd5 输出风格）', () {
    test('FIPS 标准向量', () {
      expect(
        CryptoUtils.encodeSha256('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('空串', () {
      expect(
        CryptoUtils.encodeSha256(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('中文（utf8 编码后哈希，标准值经 shasum -a 256 独立核对）', () {
      expect(
        CryptoUtils.encodeSha256('中'),
        'a567bdaa11367f260f0708391f4d10766b5962f565d9e432f17981a3584fe1e2',
      );
      expect(
        CryptoUtils.encodeSha256('中'),
        isNot(CryptoUtils.encodeSha256('国')),
      );
    });
  });

  group('H2 encodeHmacSha1（utf8 编码，默认 hex 小写）', () {
    const fox = 'The quick brown fox jumps over the lazy dog';
    const foxHmacSha1Hex = 'de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9';

    test('标准向量（hex 小写）', () {
      expect(CryptoUtils.encodeHmacSha1(fox, 'key'), foxHmacSha1Hex);
    });

    test('base64 输出（由标准向量 + SDK 编解码合成期望）', () {
      final expected = base64.encode(hex.decode(foxHmacSha1Hex));
      expect(
        CryptoUtils.encodeHmacSha1(fox, 'key', base64: true),
        expected,
      );
    });

    test('不同密钥产出不同签名', () {
      expect(
        CryptoUtils.encodeHmacSha1(fox, 'other-key'),
        isNot(foxHmacSha1Hex),
      );
    });
  });

  group('H3 encodeHmacSha256（utf8 编码，默认 hex 小写）', () {
    const fox = 'The quick brown fox jumps over the lazy dog';
    const foxHmacSha256Hex =
        'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8';

    test('标准向量（hex 小写）', () {
      expect(CryptoUtils.encodeHmacSha256(fox, 'key'), foxHmacSha256Hex);
    });

    test('base64 输出（由标准向量 + SDK 编解码合成期望）', () {
      final expected = base64.encode(hex.decode(foxHmacSha256Hex));
      expect(
        CryptoUtils.encodeHmacSha256(fox, 'key', base64: true),
        expected,
      );
    });

    test('不同密钥产出不同签名', () {
      expect(
        CryptoUtils.encodeHmacSha256(fox, 'other-key'),
        isNot(foxHmacSha256Hex),
      );
    });
  });
}
