// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/identifier/uuid_utils.dart';

void main() {
  // RFC 4122 标准的 DNS 命名空间，用作固定 namespace。
  const dnsNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

  final uuidPattern =
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  group('UuidUtils.generateV4', () {
    test('matches canonical UUID format', () {
      expect(UuidUtils.generateV4(), matches(uuidPattern));
    });

    test('version nibble is 4', () {
      final uuid = UuidUtils.generateV4();
      // 第三段首字符是版本号。
      expect(uuid[14], '4');
    });

    test('repeated calls are unique', () {
      final seen = <String>{};
      for (var i = 0; i < 1000; i++) {
        seen.add(UuidUtils.generateV4());
      }
      expect(seen.length, 1000);
    });
  });

  group('UuidUtils.generateV1', () {
    test('matches canonical UUID format', () {
      expect(UuidUtils.generateV1(), matches(uuidPattern));
    });

    test('version nibble is 1', () {
      expect(UuidUtils.generateV1()[14], '1');
    });

    test('repeated calls are unique', () {
      final seen = <String>{};
      for (var i = 0; i < 1000; i++) {
        seen.add(UuidUtils.generateV1());
      }
      expect(seen.length, 1000);
    });
  });

  group('UuidUtils.generateV5', () {
    setUp(UuidUtils.clearCache);

    test('matches canonical UUID format and version nibble is 5', () {
      final uuid = UuidUtils.generateV5(dnsNamespace, 'example.com');
      expect(uuid, matches(uuidPattern));
      expect(uuid[14], '5');
    });

    test('deterministic: same namespace + name yields same UUID', () {
      final a = UuidUtils.generateV5(dnsNamespace, 'example.com');
      final b = UuidUtils.generateV5(dnsNamespace, 'example.com');
      expect(a, b);
    });

    test('different names yield different UUIDs', () {
      final a = UuidUtils.generateV5(dnsNamespace, 'example.com');
      final b = UuidUtils.generateV5(dnsNamespace, 'other.com');
      expect(a, isNot(b));
    });

    test('known RFC 4122 test vector (DNS namespace)', () {
      // uuid 包对 v5 使用 SHA-1；DNS ns + example.com 的既定结果，
      // 钉住跨版本/跨系统一致性（这是 v5 的核心承诺）。
      expect(
        UuidUtils.generateV5(dnsNamespace, 'example.com'),
        'cfbff0d1-9375-5685-968c-48ce8b15ae17',
      );
    });

    test('clearCache does not change results (cache is transparent)', () {
      final first = UuidUtils.generateV5(dnsNamespace, 'example.com');
      UuidUtils.clearCache();
      final second = UuidUtils.generateV5(dnsNamespace, 'example.com');
      expect(second, first);
    });
  });
}
