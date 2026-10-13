// LanUtils — absorbed (as capability, rewritten for testability) from
// saas_pos_smart_edition `lib/core/utils/local_ipv4_util.dart`.
//
// Strict TDD: written first; expected to fail with compile errors before
// `lib/net/lan_utils.dart` exists. Deviations from the source on purpose:
// - scoring/filtering lives in a pure function over plain data records
//   (`NetworkInterface` is abstract and cannot be constructed in tests);
// - the POS-specific "first three octets" helper was dropped (business
//   shape, callers can split the full address themselves).

import 'package:cutils/net/lan_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('L1 私网优先级（192.168 > 10 > 172.16-31 > 其它公网）', () {
    test('四类私网同时存在时选 192.168', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['10.0.0.5']),
        (name: 'wlan0', ipv4: ['172.20.1.5']),
        (name: 'en0', ipv4: ['192.168.1.5']),
        (name: 'eth1', ipv4: ['8.8.8.8']),
      ]);
      expect(got, '192.168.1.5');
    });

    test('无 192.168 时选 10 段', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['172.20.1.5']),
        (name: 'wlan0', ipv4: ['10.0.0.5']),
      ]);
      expect(got, '10.0.0.5');
    });

    test('仅公网地址时仍然兜底返回', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['8.8.8.8']),
      ]);
      expect(got, '8.8.8.8');
    });

    test('同优先级保持先出现者（严格更大才替换）', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['192.168.1.5']),
        (name: 'wlan0', ipv4: ['192.168.0.3']),
      ]);
      expect(got, '192.168.1.5');
    });

    test('172.16-31 边界：172.15 与 172.32 落入公网档', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['172.15.0.1']),
        (name: 'wlan0', ipv4: ['172.32.0.1']),
      ]);
      // 两者同为「其它」档（rank 1），保持先出现者
      expect(got, '172.15.0.1');
    });
  });

  group('L2 排除规则', () {
    test('APIPA（169.254.x.x）被排除', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['169.254.10.20', '192.168.1.5']),
      ]);
      expect(got, '192.168.1.5');
      expect(
        LanUtils.pickBestLanIpv4(const [
          (name: 'eth0', ipv4: ['169.254.10.20']),
        ]),
        isNull,
      );
    });

    test('环回地址（127.x）被排除', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'lo0', ipv4: ['127.0.0.1', '10.1.1.1']),
      ]);
      expect(got, '10.1.1.1');
    });

    test('非点分四段地址被跳过（IO 层只映射 IPv4，此处防御）', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'eth0', ipv4: ['fe80::1', 'not-an-ip', '10.1.1.1']),
      ]);
      expect(got, '10.1.1.1');
    });
  });

  group('L3 虚拟网卡降权（不排除，仅垫底）', () {
    test('有物理网卡时优先物理', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'docker0', ipv4: ['172.17.0.1']),
        (name: 'en0', ipv4: ['10.0.0.5']),
      ]);
      expect(got, '10.0.0.5');
    });

    test('仅虚拟网卡有地址时仍兜底返回（降权非排除，对齐源实现）', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'docker0', ipv4: ['172.17.0.1']),
      ]);
      expect(got, '172.17.0.1');
    });

    test('黑名单按子串匹配（vEthernet / VMware 形态均识别为虚拟）', () {
      final got = LanUtils.pickBestLanIpv4(const [
        (name: 'vEthernet (Default Switch)', ipv4: ['172.20.0.1']),
        (name: 'VMware Network Adapter VMnet8', ipv4: ['192.168.1.5']),
        (name: 'en0', ipv4: ['10.0.0.5']),
      ]);
      expect(got, '10.0.0.5');
    });
  });

  group('L4 无可用地址返回 null', () {
    test('空列表', () {
      expect(LanUtils.pickBestLanIpv4(const []), isNull);
    });

    test('地址全被排除', () {
      expect(
        LanUtils.pickBestLanIpv4(const [
          (name: 'eth0', ipv4: ['127.0.0.1', '169.254.1.1']),
        ]),
        isNull,
      );
    });
  });
}
